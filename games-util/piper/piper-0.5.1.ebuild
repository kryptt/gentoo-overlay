# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )

inherit meson udev python-any-r1

DESCRIPTION="GTK application to configure gaming devices"
HOMEPAGE="https://github.com/libratbag/piper"
SRC_URI="https://github.com/libratbag/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="
	virtual/pkgconfig
"
RDEPEND="
	dev-libs/libratbag
	>=dev-python/pygobject-3
	dev-python/python-evdev
"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_configure() {
	meson_src_configure
}
