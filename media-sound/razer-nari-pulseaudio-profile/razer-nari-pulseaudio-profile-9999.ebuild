# Copyright 2020 Rodolfo Hansen

EAPI=7

inherit udev

DESCRIPTION="The Razer Nari is a gaming headset which has two stereo audio outputs"
HOMEPAGE="https://github.com/imustafin/razer-nari-pulseaudio-profile"
PV="master"
SRC_URI="https://github.com/imustafin/razer-nari-pulseaudio-profile/archive/${PV}.zip"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RDEPEND="virtual/udev media-sound/pulseaudio"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${PN}-${PV}"

src_compile() {
	echo "nothing to compile"
}
src_install() {
	udev_dorules 91-pulseaudio-razer-nari.rules
	dodoc README.md
	insinto /usr/share/pulseaudio/alsa-mixer/paths/
	for f in input output-{game,chat}; do
		doins "razer-nari-${f}.conf"
	done
	insinto /usr/share/pulseaudio/alsa-mixer/profile-sets/
	doins "razer-nari-usb-audio.conf"
	elog "In order for pulseaudio changes to take effect you should restart it by running:
pulseaudio -k
pulseaudio --start"
}
