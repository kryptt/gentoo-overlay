# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# the rocpd2* converters refuse to run on 3.14
PYTHON_COMPAT=( python3_{11..13} )

inherit optfeature python-single-r1

MY_ARCH="gfx1151"
MY_P="therock-dist-linux-${MY_ARCH}-${PV}"

DESCRIPTION="rocprofv3 and rocprof-compute from AMD's prebuilt TheRock ${MY_ARCH} distribution"
HOMEPAGE="
	https://github.com/ROCm/rocprofiler-sdk
	https://github.com/ROCm/rocprofiler-compute
"
SRC_URI="https://repo.amd.com/rocm/tarball-multi-arch/${MY_P}.tar.gz"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# The profiler libraries resolve libhsa-runtime64 and libamd_comgr from the
# system ROCm, so the two have to be the matching release. librocprofiler-register
# deliberately comes from dev-libs/rocprofiler-register rather than the bundled
# copy: the runtimes and the profiler have to meet in one instance of it.
# pandas/jinja/pyyaml are what the rocpd2* converters import to render a
# summary; without them rocprofv3 still writes its database but nothing can
# read it back.
RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/jinja2[${PYTHON_USEDEP}]
		dev-python/pandas[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
	')
	dev-libs/rocprofiler-register
	~dev-libs/rocm-comgr-${PV}
	~dev-libs/rocr-runtime-${PV}
"

RESTRICT="strip"
QA_PREBUILT="opt/rocprofiler-therock/.*"

# The upstream tarball is a complete 1.7G ROCm distribution; only these paths
# carry rocprofv3, rocprof-compute and what they load at runtime.
COMPONENTS=(
	"./bin/rocpd2csv"
	"./bin/rocpd2otf2"
	"./bin/rocpd2pftrace"
	"./bin/rocpd2summary"
	"./bin/rocprof-attach"
	"./bin/rocprof-compute"
	"./bin/rocprofv3"
	"./bin/rocprofv3-avail"
	"./lib/libhsa-amd-aqlprofile64.so*"
	"./lib/librocprofiler-sdk*.so*"
	"./lib/python3/site-packages"
	"./lib/python3.1[123]/site-packages"
	"./lib/rocm_sysdeps/lib"
	"./lib/rocprofiler-sdk"
	"./libexec/rocprofiler-compute"
	"./share/amd_smi"
	"./share/doc/hsa-amd-aqlprofile"
	"./share/doc/rocprofiler-compute"
	"./share/doc/rocprofiler-sdk"
	"./share/rocprofiler-sdk"
	"./share/rocprofiler-sdk-rocpd"
)

src_unpack() {
	ebegin "Unpacking the profiler subset of ${MY_P}.tar.gz"
	tar -x -z -f "${DISTDIR}/${MY_P}.tar.gz" \
		-C "${WORKDIR}" --wildcards "${COMPONENTS[@]}" || die
	eend ${?}
}

src_install() {
	# rocprofv3 derives its library paths from
	# dirname(dirname(realpath($0))), and the shipped libraries carry
	# $ORIGIN-relative RUNPATHs, so the tree has to stay self-contained
	# instead of being split over /usr/bin and /usr/$(get_libdir).
	local dest="/opt/rocprofiler-therock"

	# cp -a rather than doins: the .so symlink chains and the executable bits
	# have to survive, and doins dereferences symlinks.
	dodir "${dest}"
	cp -a bin lib libexec share "${ED}${dest}"/ || die

	# The rocprofiler-compute python tree hardcodes /opt/rocm when it reaches
	# for the *system* ROCm - libamdhip64, libhiprtc, the roctx injector.
	# On this layout that is /usr; dev-util/hip installs the
	# /usr/lib/libamdhip64.so compat symlink those ctypes loads need.
	grep -rlZ "/opt/rocm" "${ED}${dest}"/libexec/rocprofiler-compute --include="*.py" |
		xargs -0 -r sed -i -e "s:/opt/rocm:${EPREFIX}/usr:g" || die

	# librocprofiler-sdk-tool.so is the one thing that lives here rather than
	# in the system tree, so its default has to point back at this prefix.
	sed -i -e "s|Path(os.getenv(\"ROCM_PATH\", \"${EPREFIX}/usr\"))|Path(\"${dest}\")|" \
		"${ED}${dest}"/libexec/rocprofiler-compute/argparser.py || die
	grep -q "Path(\"${dest}\")" \
		"${ED}${dest}"/libexec/rocprofiler-compute/argparser.py ||
		die "rocprofiler-sdk tool path default not rewritten"

	# 'rocprof-compute profile' reads GPU specs through the amdsmi python
	# bindings, which it expects under <rocm>/share/amd_smi. ::gentoo's
	# dev-util/amdsmi stops at 7.2.0 and is pinned to rocm-core:0/7.2, so use
	# the copy from the same tarball; its libamd_smi.so wants the bundled
	# librocm_sysdeps_nl_* that LDPATH above already exposes.
	sed -i -e "s|os.getenv(\"ROCM_PATH\", \"${EPREFIX}/usr\") + \"/share/amd_smi\"|\"${dest}/share/amd_smi\"|" \
		"${ED}${dest}"/libexec/rocprofiler-compute/utils/amdsmi_interface.py || die
	grep -q "\"${dest}/share/amd_smi\"" \
		"${ED}${dest}"/libexec/rocprofiler-compute/utils/amdsmi_interface.py ||
		die "amdsmi search path not rewritten"

	local script
	for script in "${ED}${dest}"/bin/* \
			"${ED}${dest}"/libexec/rocprofiler-compute/rocprof-compute; do
		python_fix_shebang -q "${script}"
	done

	# One PATH entry beats eight wrapper scripts.
	#
	# LDPATH is not optional: rocpd/libpyrocpd.so pulls librocm_sysdeps_elf
	# directly, but its own RUNPATH only reaches ${dest}/lib, and RUNPATH is
	# not inherited from the object that triggered the load. Having
	# ${dest}/lib in the cache also lets the HSA runtime dlopen the bundled
	# libhsa-amd-aqlprofile64, which is what hardware counter collection
	# needs. Every soname under these two directories is TheRock-private.
	# The HSA runtime probes for hardware counter support with
	# dlopen("libhsa-amd-aqlprofile64.so") - unversioned, and ldconfig only
	# indexes SONAMEs, so LDPATH below cannot satisfy it. Nothing else on the
	# system ships aqlprofile, so claim the system name.
	dosym -r "${dest}/lib/libhsa-amd-aqlprofile64.so.1" \
		"/usr/$(get_libdir)/libhsa-amd-aqlprofile64.so"

	#
	# ROCM_VER is the documented fallback for rocprof-compute's ROCm version
	# probe: it reads <rocm>/.info/version, which dev-libs/rocm-core removes
	# on purpose ("too broad for standard directory"), so nothing on a Gentoo
	# system will ever provide it.
	newenvd - 99rocprofiler-therock <<-EOF
		PATH="${dest}/bin"
		LDPATH="${dest}/lib:${dest}/lib/rocm_sysdeps/lib"
		ROCM_VER="${PV}"
	EOF
}

pkg_postinst() {
	elog "Run 'env-update && source /etc/profile' to pick up ${P} in PATH."
	elog
	optfeature "PDF output from rocpd2summary" dev-python/reportlab
	elog
	elog "rocpd2otf2 additionally needs the 'otf2' python module, which is not"
	elog "packaged in ::gentoo; the other rocpd2* converters do not use it."
	elog
	elog "'rocprof-compute profile' needs nothing beyond the standard library."
	elog "'rocprof-compute analyze' additionally wants the pinned packages in"
	elog "  /opt/rocprofiler-therock/libexec/rocprofiler-compute/requirements.txt"
	elog "Most of those (dash, plotille, textual-plotext, astunparse) are not in"
	elog "::gentoo, so install them into a virtualenv and run rocprof-compute"
	elog "from it if you want the analyze/TUI front-ends."
}
