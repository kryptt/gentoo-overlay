# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils git-r3 flag-o-matic cmake-utils

DESCRIPTION="The Enlightenment Neovim Client"
HOMEPAGE="https://phab.enlightenment.org/w/projects/eovim/"

LICENSE="MIT"
SLOT="0"
IUSE=""

CDEPEND=">=dev-libs/efl-1.20.0
		>=dev-libs/msgpack-1.0.0
		>=app-editors/neovim-0.2.0"

RDEPEND="${CDEPEND}"
DEPEN=="${RDEPEND}"

EGIT_REPO_URI="https://github.com/jeanguyomarch/eovim.git"
EGIT_BRANCH="master"
KEYWORDS=""

src_prepare() {
        epatch "${FILESDIR}/assert-eovim-0.1.3.patch"
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
