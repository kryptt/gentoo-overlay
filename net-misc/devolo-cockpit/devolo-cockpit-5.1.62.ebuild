#Copyright 1999-2008 Gentoo Foundation
#Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=2
DESCRIPTION="devolo-dlan-cockpit is aconfiguration software for dLAN-networks"
HOMEPAGE="http://www.devolo.com/de/"
SRC_URI="x86? ( http://update.devolo.com/linux/apt/pool/main/d/devolo-dlan-cockpit/devolo-dlan-cockpit_${PV}-0_i386.deb )
         amd64? ( http://update.devolo.com/linux/apt/pool/main/d/devolo-dlan-cockpit/devolo-dlan-cockpit_${PV}-0_amd64.deb  )"
LICENSE="Proprietary"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

DEPEND="|| ( >=dev-util/adobe-air-runtime-2.6 ) ( app-arch/deb2targz )"
DEPEND="${RDEPEND}"
tS=${WORKDIR}/${P}

src_unpack() {
	unpack ${A}
	cd ${WORKDIR}
	echo ${WORKDIR}
	tar -xzf data.tar.gz
	rm data.tar.gz
}

src_install() {
 dodir /opt/devolo
 dodir /opt/devolo/dlancockpit
 dodir /opt/devolo/dlancockpit/share
 dodir /usr/share/icons/hicolor/32x32/apps
 dodir /usr/share/icons/hicolor/48x48/apps
 dodir /usr/share/icons/hicolor/128x128/apps
 dodir /usr/share/icons/hicolor/16x16/apps
 dodir /opt/devolo/dlancockpit/share/TroubleShoot
 dodir /opt/devolo/dlancockpit/share/META-INF
 dodir /opt/devolo/dlancockpit/share/META-INF/AIR/

 exeinto /opt/devolo/dlancockpit/bin/
 doexe ${WORKDIR}/opt/devolo/dlancockpit/bin/*
 insinto /opt/devolo/dlancockpit/share/
 doins ${WORKDIR}/opt/devolo/dlancockpit/share/*
 insinto /usr/bin/
 dobin ${WORKDIR}/usr/bin/devolonetsvc
 insinto /usr/share/applications/
 doins ${WORKDIR}/usr/share/applications/devolo-dlan-cockpit.desktop
 insinto /usr/share/icons/hicolor/32x32/apps
 doins ${WORKDIR}/usr/share/icons/hicolor/32x32/apps/devolo-dlan-cockpit.png
 insinto /usr/share/icons/hicolor/48x48/apps
 doins ${WORKDIR}/usr/share/icons/hicolor/48x48/apps/devolo-dlan-cockpit.png
 insinto /usr/share/icons/hicolor/128x128/apps
 doins ${WORKDIR}/usr/share/icons/hicolor/128x128/apps/devolo-dlan-cockpit.png
 insinto /usr/share/icons/hicolor/16x16/apps
 doins ${WORKDIR}/usr/share/icons/hicolor/16x16/apps/devolo-dlan-cockpit.png
 insinto /opt/devolo/dlancockpit/share/TroubleShoot
 doins ${WORKDIR}/usr/share/TroubleShoot/*
 insinto /opt/devolo/dlancockpit/share/META-INF
 doins ${WORKDIR}/opt/devolo/dlancockpit/share/META-INF/*
 insinto /opt/devolo/dlancockpit/share/META-INF/AIR/
 doins ${WORKDIR}/opt/devolo/dlancockpit/share/META-INF/AIR/*
 exeinto /etc/init.d
 doexe ${WORKDIR}/etc/init.d/devolonetsvc
 exeinto /etc/cron.daily
 doexe ${WORKDIR}/etc/cron.daily/devolo-updates
}
