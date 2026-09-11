# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYPI_PKGNAME="semgrep"
if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/semgrep/semgrep.git"
else
	inherit pypi
	KEYWORDS="~amd64"
fi
DESCRIPTION="Static analysis tool for detecting bugs and enforcing code standards"
HOMEPAGE="https://semgrep.github.io/"
LICENSE="LGPL-2.1"
SLOT="0"
RESTRICT="mirror"

BDEPEND="
	dev-python/setuptools
	dev-python/wheel
"
RDEPEND="
	>=dev-lang/python-3.10:3.10
"
DEPEND="${RDEPEND}"

DISTUTILS_USE_PEP517="setuptools"
python_install_all() {
	dodoc README.md
}
