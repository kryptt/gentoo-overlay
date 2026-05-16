# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

MY_SERVER_PV="${PV}"
MY_SERVER_P="scrcpy-server-v${MY_SERVER_PV}"

DESCRIPTION="Display and control your Android device"
HOMEPAGE="https://github.com/Genymobile/scrcpy"
SRC_URI="
	https://github.com/Genymobile/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/Genymobile/${PN}/releases/download/v${MY_SERVER_PV}/${MY_SERVER_P}
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="v4l wayland"

RESTRICT="test"

RDEPEND="
	>=media-libs/libsdl3-3.2.0
	media-video/ffmpeg:=
	dev-libs/libusb:1
	v4l? ( media-libs/libv4l )
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_configure() {
	local emesonargs=(
		-Db_lto=true
		-Dprebuilt_server="${DISTDIR}/${MY_SERVER_P}"
		$(meson_use v4l v4l2)
	)
	meson_src_configure
}
