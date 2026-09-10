# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# ROCm 7.14 is built by TheRock; components are no longer tagged "rocm-${PV}".
ROCM_TAG="therock-10.0"

inherit cmake

MY_P=llvm-project-${ROCM_TAG}
components=( "amd/comgr" )

DESCRIPTION="Radeon Open Compute Code Object Manager"
HOMEPAGE="https://github.com/ROCm/llvm-project/tree/amd-staging/amd/comgr"
SRC_URI="https://github.com/ROCm/llvm-project/archive/${ROCM_TAG}.tar.gz -> ${MY_P}.tar.gz"
S="${WORKDIR}/${MY_P}/${components[0]}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE="test"
RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}/${PN}-6.4.1-extend-isa-compatibility-check.patch"
	"${FILESDIR}/${PN}-6.1.0-dont-add-nogpulib.patch"
	"${FILESDIR}/${PN}-7.14.0-missing-include.patch"
)

RDEPEND="
	dev-libs/rocm-device-libs:${SLOT}
	sys-devel/llvm-roc:=
	dev-util/hipcc:${SLOT}
"
DEPEND="${RDEPEND}"

# Circular dependency: to build tests, hip compiler must be functional
BDEPEND="test? ( dev-util/hip:${SLOT} )"

CMAKE_BUILD_TYPE=Release

src_unpack() {
	if [[ ${PV} == *9999 ]] ; then
		git-r3_fetch
		git-r3_checkout '' . '' "${components[@]}"
	else
		archive="${MY_P}.tar.gz"
		ebegin "Unpacking from ${archive}"
		tar -x -z -o \
			-f "${DISTDIR}/${archive}" \
			"${components[@]/#/${MY_P}/}" || die
		eend ${?}
	fi
}

src_prepare() {
	# cmake/opencl_header.cmake globs opencl-c-base.h below the Clang
	# install prefix; with the self-contained llvm-roc prefix that just works.
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_PREFIX_PATH="${EPREFIX}/usr/lib/llvm/roc"
		-DCMAKE_STRIP=""  # disable stripping defined at lib/comgr/CMakeLists.txt:58
		-DBUILD_TESTING=$(usex test ON OFF)
		-DCOMGR_DISABLE_SPIRV=ON  # requires ROCm/SPIRV-LLVM-Translator (fork of dev-util/spirv-llvm-translator)
		# Link the fork's LLVM/Clang statically and hide its symbols behind
		# comgr's version script, the way TheRock builds it.
		-DCOMGR_STATIC_LLVM=ON
	)
	# Prevent CMake from finding systemwide hip, which breaks tests
	use test && mycmakeargs+=( -DCMAKE_DISABLE_FIND_PACKAGE_hip=ON )
	cmake_src_configure
}

src_test() {
	cmake_src_test
}
