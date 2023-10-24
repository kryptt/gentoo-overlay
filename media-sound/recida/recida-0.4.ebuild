# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson ninja-utils git-r3

EGIT_REPO_URI="https://github.com/GhostNaN/recidia-audio-visualizer.git"

DESCRIPTION="A highly customizable real time audio visualizer on Linux"
HOMEPAGE="https://github.com/GhostNaN/recidia-audio-visualizer"

SRC_URI="https://github.com/GhostNaN/recidia-audio-visualizer/archive/${PV}.tar.gz"

LICENSE="GPL-3.0"
SLOT="0"
IUSE="ncurses"

RESTRICT="test"

COMMON_DEPEND="sci-libs/gsl
	media-libs/glm
	sci-libs/fftw
	dev-libs/libconfig
	ncurses? ( sci-libs/ncurses )
	dev-qt/qtbase:6
	media-libs/shaderc
	media-libs/vulkan-loader"
DEPEND="${COMMON_DEPEND}"
RDEPEND="${COMMON_DEPEND}"
BDEPEND="${COMMON_DEPEND} dev-util/vulkan-headers"

src_configure() {
	local emesonargs=(
		-Db_lto=true
	)
	meson_src_configure
}
