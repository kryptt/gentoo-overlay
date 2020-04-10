# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )

inherit meson udev python-any-r1

DESCRIPTION="Library to configure gaming mice"
HOMEPAGE="https://github.com/libratbag/libratbag"
SRC_URI="https://github.com/${PN}/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc test"
RESTRICT="!test? ( test )"

DEPEND="
	virtual/pkgconfig
	doc? ( app-doc/doxygen )
	test? ( dev-util/valgrind )
"
RDEPEND="
	dev-libs/libevdev
	virtual/libudev
"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_prepare() {
	default

	sed '/default:/d' -i meson_options.txt || die
}

src_configure() {
	local emesonargs=(
		-Dudev-dir=$(get_udevdir)
		$(meson_use doc documentation)
		$(meson_use test tests)
	)
	meson_src_configure
}
