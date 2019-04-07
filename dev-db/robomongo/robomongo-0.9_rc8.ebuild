# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
CMAKE_BUILD_TYPE=Release
inherit cmake-utils git-2

DESCRIPTION="Robomongo — is a shell-centric crossplatform MongoDB management
tool."

HOMEPAGE="http://www.robomongo.org/"
#SRC_URI="https://github.com/paralect/robomongo/archive/v${PV}.tar.gz"
EGIT_REPO_URI="git://github.com/paralect/robomongo.git"
EGIT_BRANCH="v0.9"
EGIT_COMMIT="968a83c38058989a859e4ede93936805820a4e93"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=">dev-qt/qtcore-5
		>dev-qt/qtgui-5
		>dev-qt/qtdbus-5
		>dev-qt/qtprintsupport-5"

RDEPEND="${DEPEND}"

S=${WORKDIR}"/"${P}

src_prepare() {
	epatch "${FILESDIR}"/fix-qt54.patch
	distutils_src_prepare
}

src_configure() {
	cmake-utils_src_configure
}

src_install() {
	cd ${BUILD_DIR}
	dobin src/build/robomongo
	domenu robomongo/robomongo.desktop
	cd ${S}
	doicon install/linux/robomongo.png
	dodoc whats-new.txt COPYRIGHT LICENSE README.md shortcuts.txt
}
