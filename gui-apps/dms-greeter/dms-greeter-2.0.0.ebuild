# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion tmpfiles

# Standalone greetd greeter split out of dux-desktop/dux-shell at 2.0.0 (the
# shell ebuild dropped its greeter USE flag and stopped installing
# /usr/bin/dms-greeter). Lives here until ::guru packages it; switch to the
# guru package and drop this one when that happens.
#
# The release tarball carries the dux-qml-common submodule and vendored Go
# modules, so the build is fully offline. The Quickshell UI is embedded into
# the binary via the `withshell` build tag.

DESCRIPTION="greetd greeter with the Dux Shell lock-screen look"
HOMEPAGE="https://github.com/duxlabs-dev/dux-greeter"
SRC_URI="https://github.com/duxlabs-dev/dux-greeter/releases/download/v${PV}/dank-greeter-${PV}.tar.gz"
S="${WORKDIR}/dank-greeter-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Older dux-shell installs /usr/bin/dms-greeter itself.
RDEPEND="
	!<dux-desktop/dux-shell-2.0.0
	gui-apps/quickshell
	gui-libs/greetd
"
BDEPEND=">=dev-lang/go-1.27"

# Go binary, built with -s -w by upstream's Makefile.
QA_PRESTRIPPED="usr/bin/dms-greeter"

src_compile() {
	export GOFLAGS="-mod=vendor" GOCACHE="${T}/go-cache" GOTOOLCHAIN=local
	emake -C core build VERSION="${PV}" COMMIT=release
	local c
	for c in bash zsh fish; do
		core/bin/dms-greeter completion ${c} > dms-greeter.${c} || die
	done
}

src_install() {
	dobin core/bin/dms-greeter
	newbashcomp dms-greeter.bash dms-greeter
	newzshcomp dms-greeter.zsh _dms-greeter
	newfishcomp dms-greeter.fish dms-greeter.fish
	newtmpfiles "${FILESDIR}"/dms-greeter.tmpfiles dms-greeter.conf
	dodoc README.md
	docinto examples
	dodoc assets/examples/*
}

pkg_postinst() {
	tmpfiles_process dms-greeter.conf
	elog "greetd: set default_session command to '/usr/bin/dms-greeter --command niri'"
	elog "Run 'dms-greeter sync' as your user to copy your DMS theme to the login screen."
}
