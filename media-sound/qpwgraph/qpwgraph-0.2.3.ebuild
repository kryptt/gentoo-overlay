# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg cmake

DESCRIPTION="PipeWire Graph Qt GUI Interface"
HOMEPAGE="https://gitlab.freedesktop.org/rncbc/qpwgraph"
SRC_URI="https://gitlab.freedesktop.org/rncbc/qpwgraph/-/archive/v${PV}/qpwgraph-v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	media-video/pipewire
"
DEPEND="${RDEPEND}"

DOCS=(
	ChangeLog
	README.md
)

src_unpack() {
	default
	mv qpwgraph-v${PV} qpwgraph-${PV}
}

src_configure() {
	cmake_src_configure
}

src_install() {
	cmake_src_install
	einstalldocs
}
