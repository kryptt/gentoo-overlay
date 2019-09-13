# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python{2_7,3_5,3_6} )

inherit eutils python-single-r1 flag-o-matic cmake-utils

DESCRIPTION="The Enlightenment Neovim Client"
HOMEPAGE="https://phab.enlightenment.org/w/projects/eovim/"
SRC_URI="https://github.com/jeanguyomarch/eovim/archive/v${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

CDEPEND=">=dev-libs/efl-1.20.0
		>=dev-libs/msgpack-1.0.0
		>=dev-python/jinja-2.7[${PYTHON_USEDEP}]
		>=app-editors/neovim-0.2.0"

RDEPEND="${CDEPEND}"
DEPEN=="${RDEPEND}"

src_prepare() {
        cmake-utils_src_prepare
}

src_configure() {
		#./scripts/get-msgpack.sh
        local mycmakeargs
		mycmakeargs=(
				-DCMAKE_BUILD_TYPE=RELEASE
		)
		cmake-utils_src_configure
}

src_install() {
        cmake-utils_src_install
}
