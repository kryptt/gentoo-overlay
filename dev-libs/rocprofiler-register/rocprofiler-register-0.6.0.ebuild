# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# ROCm 7.14 is built by TheRock; components are no longer tagged "rocm-${PV}".
ROCM_TAG="therock-7.14"

inherit cmake

DESCRIPTION="Registration library letting ROCm runtimes hand their API tables to profilers"
HOMEPAGE="https://github.com/ROCm/rocm-systems/tree/develop/projects/rocprofiler-register"
SRC_URI="https://github.com/ROCm/rocm-systems/releases/download/${ROCM_TAG}/${PN}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-cpp/glog:=
	dev-libs/libfmt:=
"
DEPEND="${RDEPEND}"

src_prepare() {
	# upstream pins CMAKE_INSTALL_LIBDIR to "lib" right after including
	# GNUInstallDirs, which loses the lib64 layout
	sed -e '/set(CMAKE_INSTALL_LIBDIR "lib")/d' -i CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		# glog and fmt are vendored as git submodules that the release
		# tarball ships empty; use the system copies instead
		-DROCPROFILER_REGISTER_BUILD_GLOG=OFF
		-DROCPROFILER_REGISTER_BUILD_FMT=OFF
		-DROCPROFILER_REGISTER_BUILD_TESTS=OFF
		-DROCPROFILER_REGISTER_BUILD_SAMPLES=OFF
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=ON
	)

	cmake_src_configure
}
