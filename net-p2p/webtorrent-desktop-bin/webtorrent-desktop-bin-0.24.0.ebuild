# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN=${PN/-bin/}

DESCRIPTION="Streaming torrent app for Linux (BitTorrent/WebTorrent)"
HOMEPAGE="https://webtorrent.io/desktop"
SRC_URI="https://github.com/webtorrent/${MY_PN}/releases/download/v${PV}/WebTorrent-v${PV}-linux-x64.zip"
S="${WORKDIR}/WebTorrent-linux-x64"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

QA_PREBUILT="opt/${MY_PN}/WebTorrent"
RESTRICT="strip"

BDEPEND="app-arch/unzip"

src_install() {
	insinto /opt/${MY_PN}
	doins -r *

	exeinto /opt/${MY_PN}
	doexe WebTorrent

	dosym /opt/${MY_PN}/WebTorrent /usr/bin/${MY_PN}
}
