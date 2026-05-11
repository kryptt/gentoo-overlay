# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Transparent terminal session manager with attach/detach support"
HOMEPAGE="https://github.com/mobydeck/atch"
SRC_URI="https://github.com/mobydeck/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# No optional features warranting USE flags — the only compile-time knobs are
# buffer sizes (SCROLLBACK_SIZE, LOG_MAX_SIZE) which are better set via CFLAGS.

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS} -I. -DPACKAGE_VERSION=\\\"${PV}\\\"" \
		LDFLAGS="${LDFLAGS}" \
		STATIC_FLAG="" \
		VERSION="${PV}" \
		atch
}

src_install() {
	dobin atch
	dodoc README.md
}
