# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python2_7 )

inherit distutils-r1

DESCRIPTION="A screencast tool to display your keys inspired by Screenflick"

HOMEPAGE="https://github.com/wavexx/${PN}"

SRC_URI="${HOMEPAGE}/archive/${PN}-${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
	dev-python/setuptools-git[${PYTHON_USEDEP}]
	dev-python/python-distutils-extra[${PYTHON_USEDEP}]
"

RDEPEND="
	${DEPEND}
	dev-python/pygtk[${PYTHON_USEDEP}]
	dev-python/pycairo[${PYTHON_USEDEP}]
	x11-misc/slop
	media-fonts/fontawesome
"

S="${WORKDIR}/${PN}-${PN}-${PV}"

