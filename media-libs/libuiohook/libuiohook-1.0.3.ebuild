EAPI=6

inherit eutils autotools

DESCRIPTION="A multi-platform C library to provide global keyboard and mouse hooks from userland."
HOMEPAGE="https://github.com/kwhat/libuiohook"
SRC_URI="https://github.com/kwhat/libuiohook/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"

src_prepare() {
	default
	eautoreconf || die
}

src_configure() {
	econf
}

src_install() {
	emake DESTDIR="${D}" install || die
}
