# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit udev

DESCRIPTION="udev rules granting the seat user access to LEGO hubs (SPIKE, MINDSTORMS)"
HOMEPAGE="https://github.com/pybricks/pbrick-rules"
SRC_URI="https://github.com/pybricks/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Upstream ships only a Debian package; the rules file is all there is.
# Same name and priority dh_installudev gives it on Debian/Ubuntu.
# These cover the raw USB device (WebUSB/DFU flashing). The hub's serial node
# (/dev/ttyACM*, used by the SPIKE web app over Web Serial) is not covered:
# the user needs the dialout group for that.
src_install() {
	udev_newrules debian/${PN}.pbrick.udev 60-pbrick.rules
	dodoc README.md
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
