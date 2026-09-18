# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_ARCH="gfx1151"
MY_P="therock-dist-linux-${MY_ARCH}-${PV}"

DESCRIPTION="ROCm ${PV} math libraries from AMD's prebuilt TheRock ${MY_ARCH} distribution"
HOMEPAGE="https://github.com/ROCm/rocm-libraries"
SRC_URI="https://stable.repo.amd.com/rocm/core/tarball/${MY_P}.tar.gz"
S="${WORKDIR}"

LICENSE="MIT BSD Apache-2.0"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="-* ~amd64"

# These are AMD's own gfx1151 builds. Building this set from source instead
# means rocBLAS + hipBLASLt Tensile codegen and Composable Kernel, which is
# a multi-hour build per library and produces untuned kernels for gfx1151 --
# the tuning data is exactly what AMD ships here.
#
# Everything links libamdhip64.so.7 / libhiprtc.so.7, which is the SONAME
# dev-util/hip installs, so these drop onto the source-built runtime. They
# deliberately do NOT bring the tarball's libamdhip64, libamd_comgr,
# libhsa-runtime64 or LLVM: one instance of each of those, from source.
RDEPEND="
	~dev-util/hip-${PV}
	~dev-libs/rocm-comgr-${PV}
	~dev-libs/rocr-runtime-${PV}
"

RESTRICT="strip test"
QA_PREBUILT="usr/lib64/.*"

# The upstream tarball is a complete 1.7G ROCm distribution. These are the
# math libraries, their headers, their CMake packages, the Tensile/rocFFT
# kernel databases, and the three private libraries hipBLASLt links
# (origami, rocroller, roctx64) plus AMD's vendored sysdeps that the
# $ORIGIN-relative RUNPATHs reach for.
COMPONENTS=(
	"./include/ck"
	"./include/ck_tile"
	"./include/hipblas"
	"./include/hipblas-common"
	"./include/hipblaslt*"
	"./include/hipcub"
	"./include/hipfft"
	"./include/hiprand"
	"./include/hipsolver"
	"./include/hipsparse"
	"./include/rocblas"
	"./include/rocfft"
	"./include/rocprim"
	"./include/rocrand"
	"./include/rocsolver"
	"./include/rocsparse"

	"./lib/libdevice_*.a"
	"./lib/libhipblas.so*"
	"./lib/libhipblaslt.so*"
	"./lib/libhipfft.so*"
	"./lib/libhipfftw.so*"
	"./lib/libhiprand.so*"
	"./lib/libhipsolver.so*"
	"./lib/libhipsparse.so*"
	"./lib/liborigami.so*"
	"./lib/librocblas.so*"
	"./lib/librocfft.so*"
	"./lib/librocrand.so*"
	"./lib/librocroller.so*"
	"./lib/librocsolver.so*"
	"./lib/librocsparse.so*"
	"./lib/libroctx64.so*"

	"./lib/hipblaslt"
	"./lib/rocblas"
	"./lib/rocfft"
	"./lib/rocsparse"

	"./lib/cmake/composable_kernel"
	"./lib/cmake/hipblas"
	"./lib/cmake/hipblas-common"
	"./lib/cmake/hipblaslt"
	"./lib/cmake/hipcub"
	"./lib/cmake/hipfft"
	"./lib/cmake/hiprand"
	"./lib/cmake/hipsolver"
	"./lib/cmake/hipsparse"
	"./lib/cmake/mxDataGenerator"
	"./lib/cmake/origami"
	"./lib/cmake/rocblas"
	"./lib/cmake/rocfft"
	"./lib/cmake/rocprim"
	"./lib/cmake/rocrand"
	"./lib/cmake/rocsolver"
	"./lib/cmake/rocsparse"

	"./lib/rocm_sysdeps/lib"
)

src_unpack() {
	ebegin "Unpacking the math subset of ${MY_P}.tar.gz"
	tar -x -z -f "${DISTDIR}/${MY_P}.tar.gz" \
		-C "${WORKDIR}" --wildcards "${COMPONENTS[@]}" || die
	eend ${?}
}

src_install() {
	# cp -a, not doins: the .so symlink chains have to survive, and the
	# libraries' RUNPATHs are "$ORIGIN/rocm_sysdeps/lib", so that directory
	# has to sit beside them in the same libdir.
	dodir "/usr/$(get_libdir)"
	cp -a lib/. "${ED}/usr/$(get_libdir)/" || die

	dodir /usr/include
	cp -a include/. "${ED}/usr/include/" || die
}
