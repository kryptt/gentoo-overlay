# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

# repoman gives LIVEVCS.unmasked even with EGIT_COMMIT, so create snapshot
inherit eutils java-pkg-2 # git-r3

L_PN="sbt-launch"
L_P="${L_PN}-${PV}"

SV="2.12"

DESCRIPTION="sbt is a build tool for Scala and Java projects that aims to do the basics well"
HOMEPAGE="http://www.scala-sbt.org/"
EGIT_COMMIT="v${PV}"
EGIT_REPO_URI="https://github.com/sbt/sbt.git"
SRC_URI="https://github.com/sbt/sbt/releases/download/v${PV}/${P}.tgz"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND=">=virtual/jdk-1.8
	>=dev-lang/scala-2.12.0:${SV}"
RDEPEND=">=virtual/jre-1.8
	>=dev-lang/scala-2.12.0:${SV}"

# test hangs or fails
RESTRICT="test"

JAVA_GENTOO_CLASSPATH="scala-${SV}"

S="${WORKDIR}/sbt"

src_unpack() {
	mkdir -p "${S}" || die "Can't mkdir ${S}"
	cd "${S}"	|| die "Can't enter ${S}"
	for f in ${A} ; do
		[[ ${f} == *".tar."* ]] && unpack ${f}
		[[ ${f} == *".tgz"* ]] && unpack ${f}
	done
}

src_test() {
	export PATH="${EROOT}usr/share/scala-${SV}/bin:${S}:${PATH}"
	"${S}/${P}" -Dsbt.log.noformat=true test || die
}

src_compile() { :; }

src_install() {
	local ja="-Dsbt.version=${PV} -Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled"
	java-pkg_dojar "${S}/sbt/bin/sbt-launch.jar"
	java-pkg_dojar "${S}/sbt/bin/java9-rt-export.jar"
	java-pkg_dolauncher sbt --jar sbt-launch.jar --java_args "${ja}"
}
