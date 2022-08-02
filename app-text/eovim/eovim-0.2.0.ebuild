# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

inherit distutils-r1 cmake

DESCRIPTION="The Enlightenment Neovim Client"
HOMEPAGE="https://phab.enlightenment.org/w/projects/eovim/"
SRC_URI="https://github.com/jeanguyomarch/eovim/archive/v${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="
		>=app-editors/neovim-0.2.0
		>=dev-libs/efl-1.20.0
		>=dev-libs/msgpack-1.0.0
		>=dev-python/jinja-2.7[${PYTHON_USEDEP}]"

DEPEND="${RDEPEND}"

src_prepare() {
		cmake_src_prepare
}

src_configure() {
		#./scripts/get-msgpack.sh
		local mycmakeargs
		mycmakeargs=(
				-DCMAKE_BUILD_TYPE=RELEASE
		)
		cmake_src_configure
}

src_install() {
		cmake_src_install
}
