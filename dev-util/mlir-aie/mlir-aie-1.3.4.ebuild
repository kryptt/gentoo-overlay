# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# MLIR-AIE (IRON) — AMD/Xilinx's MLIR-based dataflow compiler for the AI Engine
# array, plus the IRON Python API ("import aie") used to author and build
# kernels for Ryzen AI / XDNA NPUs. It drives dev-util/llvm-aie (Peano) as its
# low-level backend and needs XRT at runtime for on-device execution.
#
# Like Peano, upstream ships prebuilt wheels. Unlike Peano, these are
# CPython-ABI-specific. Upstream builds cp311..cp314; Gentoo's python3_11 is
# historical, so this ebuild targets the still-supported 3.12..3.14 overlap.
# We repackage the wheel matching the
# selected PYTHON_SINGLE_TARGET rather than build the MLIR dialect from source
# (which would require checking out the pinned llvm/llvm-project commit
# 068c6c5c0c8a0555036a2ff09a99f486548e6e8d and a full MLIR build).
#
# Version pin contract (from utils/peano-requirements.txt @ v1.3.4):
#   mlir-aie 1.3.4  <=>  llvm-aie (Peano) 21.0.0.2026070801+4fb2354f
# Bump the two together, mirroring upstream's `update-peano` CI workflow.
#
# TODO(manifest): the four cpXXX wheels are ~232 MB each. Manifest generation
# requires fetching all of them; not generated here. Run
#   DISTDIR=<dir> ebuild mlir-aie-1.3.4.ebuild manifest
# after staging the wheels (they live on the v1.3.4 release, which unlike the
# Peano `nightly` release is NOT overwritten, so these URLs are durable).
# TODO(layout): the wheel's internal .data/{scripts,data,platlib} split is
# handled generically below per PEP 427, but should be validated against the
# real wheel contents (aie-opt, aie-translate, aiecc.py placement).

PYTHON_COMPAT=( python3_{12..14} )
inherit python-single-r1

DESCRIPTION="MLIR-AIE / IRON: MLIR dataflow compiler + Python API for AMD XDNA NPUs"
HOMEPAGE="https://github.com/Xilinx/mlir-aie"

WHEEL_PLATFORM="manylinux_2_35_x86_64"
WHEEL_BASE="https://github.com/Xilinx/mlir-aie/releases/download/v${PV}"

# CPython-ABI-specific wheels: fetch only the one matching the chosen target.
# USE conditionals key off the python-single-r1 PYTHON_SINGLE_TARGET flags.
SRC_URI="
	python_single_target_python3_12? ( ${WHEEL_BASE}/mlir_aie-${PV}-cp312-cp312-${WHEEL_PLATFORM}.whl )
	python_single_target_python3_13? ( ${WHEEL_BASE}/mlir_aie-${PV}-cp313-cp313-${WHEEL_PLATFORM}.whl )
	python_single_target_python3_14? ( ${WHEEL_BASE}/mlir_aie-${PV}-cp314-cp314-${WHEEL_PLATFORM}.whl )
"
S="${WORKDIR}"

LICENSE="Apache-2.0-with-LLVM-exceptions"
SLOT="0"
KEYWORDS="~amd64"

# Prebuilt native binaries + .so bindings; no arm64 wheel.
RESTRICT="strip"
QA_PREBUILT="usr/lib/python*/site-packages/aie/*"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# Pin the exact CI-matched Peano build; XRT provides on-device execution
# (xrt-smi + libs). The amdxdna kernel driver (dev-libs/xdna-driver) and a
# >=6.17 kernel are runtime prerequisites but are handled out-of-band.
RDEPEND="
	${PYTHON_DEPS}
	~dev-util/llvm-aie-21.0.0.2026070801
	dev-util/xrt
"
DEPEND="${RDEPEND}"
BDEPEND="app-arch/unzip"

src_unpack() {
	# Select the wheel matching the active interpreter's ABI tag, e.g.
	# python3.12 -> cp312.
	local cptag="cp${EPYTHON#python}"
	cptag="${cptag/./}"
	WHEEL="mlir_aie-${PV}-${cptag}-${cptag}-${WHEEL_PLATFORM}.whl"
	[[ -f ${DISTDIR}/${WHEEL} ]] || die "expected wheel ${WHEEL} not fetched"
	unzip -q "${DISTDIR}/${WHEEL}" -d "${WORKDIR}/wheel" || die
}

src_install() {
	local sitedir wheel_root data_dir
	sitedir="$(python_get_sitedir)"
	wheel_root="${WORKDIR}/wheel"
	data_dir="${wheel_root}/mlir_aie-${PV}.data"

	# PEP 427 wheel layout:
	#   <name>.data/scripts/  -> /usr/bin
	#   <name>.data/data/     -> /usr (prefix)
	#   <name>.data/purelib|platlib/ -> site-packages
	#   everything else (packages + dist-info) -> site-packages
	if [[ -d ${data_dir} ]]; then
		if [[ -d ${data_dir}/scripts ]]; then
			exeinto /usr/bin
			doexe "${data_dir}"/scripts/*
			rm -r "${data_dir}/scripts" || die
		fi
		if [[ -d ${data_dir}/data ]]; then
			insinto /usr
			doins -r "${data_dir}"/data/*
			rm -r "${data_dir}/data" || die
		fi
		local pl
		for pl in purelib platlib; do
			if [[ -d ${data_dir}/${pl} ]]; then
				insinto "${sitedir}"
				doins -r "${data_dir}/${pl}"/*
				rm -r "${data_dir}/${pl}" || die
			fi
		done
		# any remaining .data subdirs (headers/) are non-fatal; drop the shell
		rmdir "${data_dir}" 2>/dev/null
	fi

	# Remaining top-level entries are the importable package(s) + dist-info.
	insinto "${sitedir}"
	doins -r "${wheel_root}"/*

	# Restore exec bits on any native tools shipped inside the package tree
	# (aie-opt, aie-translate, clang wrappers, etc.) and byte-compile.
	local f
	while IFS= read -r -d '' f; do
		fperms +x "${f#${ED}}"
	done < <(find "${ED}${sitedir}" -type f \( -name 'aie-*' -o -name '*.so' \) -print0)

	python_optimize "${ED}${sitedir}"

	# Expose the install root for IRON tooling (aiecc.py, env_setup.sh style).
	newenvd - 61mlir-aie <<-EOF
		# dev-util/mlir-aie (IRON) install root.
		MLIR_AIE_INSTALL_DIR=${EPREFIX}${sitedir}/aie
	EOF
}

pkg_postinst() {
	elog "MLIR-AIE (IRON) installed for ${EPYTHON}."
	elog "Python API: 'import aie' (IRON). Backend: dev-util/llvm-aie (Peano),"
	elog "located via PEANO_INSTALL_DIR=/usr/lib/llvm-aie."
	elog
	elog "On-device execution needs XRT + the amdxdna driver and a >=6.17"
	elog "kernel. Verify with: xrt-smi examine  (expect /dev/accel0)."
	elog
	elog "Note: the in-process XRT python binding (pyxrt) upstream supports"
	elog "Python 3.12 only; select PYTHON_SINGLE_TARGET=python3_12 if you need it."
}
