# Copyright 2016-2017 Jan Chren (rindeal)
# Distributed under the terms of the GNU General Public License v2

EAPI=6

JBIJ_PN_PRETTY='IntelliJ IDEA'
JBIJ_URI="idea/ideaIU-${PV}"

inherit jetbrains-intellij

DESCRIPTION="${JBIJ_PN_PRETTY} is a capable and ergonomic Java IDE"

IUSE_A=( android kotlin spy-js svn groovy )

inherit arrays

src_unpack() {
	local JBIJ_TAR_EXCLUDE=()
	use android	|| JBIJ_TAR_EXCLUDE+=( 'plugins/android' )
	use kotlin	|| JBIJ_TAR_EXCLUDE+=( 'plugins/Kotlin' )
	use spy-js	|| JBIJ_TAR_EXCLUDE+=( 'plugins/spy-js' )
	use svn		|| JBIJ_TAR_EXCLUDE+=( 'plugins/svn4idea' )
	use groovy	|| JBIJ_TAR_EXCLUDE+=( 'plugins/Groovy' )

	jetbrains-intellij_src_unpack
}

JBIJ_DESKTOP_EXTRAS=(
	"MimeType=text/plain;text/x-java-source;text/x-java-properties;"
)
