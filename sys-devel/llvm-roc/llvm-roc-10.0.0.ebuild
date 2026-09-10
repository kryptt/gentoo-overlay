# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# ROCm is built by TheRock; its LLVM fork is tagged "therock-<major>.<minor>".
# PV tracks the ROCm release the fork belongs to, not LLVM's own version
# (this tree reports itself as clang 23.0.0git).
ROCM_TAG="therock-$(ver_cut 1-2)"
PYTHON_COMPAT=( python3_{11..14} )

inherit cmake flag-o-matic python-any-r1

MY_P="llvm-project-${ROCM_TAG}"

DESCRIPTION="AMD's LLVM fork (clang + lld) for ROCm, as shipped by TheRock"
HOMEPAGE="https://github.com/ROCm/llvm-project"
SRC_URI="https://github.com/ROCm/llvm-project/archive/${ROCM_TAG}.tar.gz -> ${MY_P}.tar.gz"
S="${WORKDIR}/${MY_P}/llvm"

LICENSE="Apache-2.0-with-LLVM-exceptions UoI-NCSA MIT BSD public-domain rc"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE="debug"

RDEPEND="
	app-arch/zstd:=
	sys-libs/zlib:=
"
DEPEND="${RDEPEND}"
BDEPEND="${PYTHON_DEPS}"

CMAKE_BUILD_TYPE=Release

src_configure() {
	# Match TheRock: a plain, LTO-free build of the fork. AMD validates
	# ROCm against exactly this tree built exactly this way; a miscompiled
	# compiler is the hardest kind of ROCm bug to find.
	filter-lto
	strip-unsupported-flags

	local mycmakeargs=(
		# Self-contained prefix, lib/ (not lib64/) like AMD's own layout:
		# clang looks for the ROCm device libs in
		# <resource-dir>/lib/amdgcn/bitcode, and rocm-device-libs installs
		# its symlink there.
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/llvm/roc"
		-DLLVM_LIBDIR_SUFFIX=
		-DLLVM_APPEND_VC_REV=OFF
		-DLLVM_HOST_TRIPLE="${CHOST}"
		-DPython3_EXECUTABLE="${PYTHON}"

		# comgr's README: at least llvm;clang;lld with AMDGPU;X86.
		-DLLVM_ENABLE_PROJECTS="clang;lld"
		-DLLVM_TARGETS_TO_BUILD="AMDGPU;X86"

		# Both the dylibs (tools link them) and the per-component static
		# archives: rocm-comgr links LLVM statically (COMGR_STATIC_LLVM),
		# the way TheRock does.
		-DBUILD_SHARED_LIBS=OFF
		-DLLVM_BUILD_LLVM_DYLIB=ON
		-DLLVM_LINK_LLVM_DYLIB=ON
		-DCLANG_LINK_CLANG_DYLIB=ON
		-DLLVM_BUILD_LLVM_C_DYLIB=OFF

		# ROCm ships against an assertions-off LLVM; with them on, comgr
		# trips an unchecked Expected<T> and every HIP binary aborts.
		-DLLVM_ENABLE_ASSERTIONS=$(usex debug)

		-DLLVM_ENABLE_ZLIB=FORCE_ON
		-DLLVM_ENABLE_ZSTD=FORCE_ON
		-DLLVM_ENABLE_LIBXML2=OFF
		-DLLVM_ENABLE_LIBEDIT=OFF
		-DLLVM_ENABLE_FFI=OFF
		-DLLVM_ENABLE_LIBPFM=OFF
		-DLLVM_ENABLE_Z3_SOLVER=OFF
		-DLLVM_ENABLE_BINDINGS=OFF
		-DLLVM_INCLUDE_BENCHMARKS=OFF
		-DLLVM_INCLUDE_DOCS=OFF
		-DLLVM_INCLUDE_EXAMPLES=OFF
		-DLLVM_INCLUDE_TESTS=OFF
		-DOCAMLFIND=NO

		# TheRock's clang defaults, minus compiler-rt (not built here;
		# host code links libgcc like every other compiler on the box).
		-DCLANG_DEFAULT_LINKER=lld
		-DCLANG_DEFAULT_RTLIB=libgcc
		-DCLANG_DEFAULT_UNWINDLIB=libgcc
		-DCLANG_ENABLE_ARCMT=OFF
		-DCLANG_ENABLE_STATIC_ANALYZER=OFF
		-DCLANG_INCLUDE_DOCS=OFF
		-DCLANG_INCLUDE_TESTS=OFF
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	# The dylibs are only ever wanted by the ROCm packages built against
	# this prefix; expose them to the loader without putting the fork's
	# clang on anyone's PATH.
	newenvd - "99${PN}" <<-_EOF_
		LDPATH="${EPREFIX}/usr/lib/llvm/roc/lib"
	_EOF_
}
