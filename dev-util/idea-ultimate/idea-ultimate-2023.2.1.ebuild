# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit desktop wrapper

SLOT="0"
MY_S="${PN}-IU-${PV}"

# upstream stable
KEYWORDS="~amd64 ~x86"
SRC_URI="https://download.jetbrains.com/idea/ideaIU-${PV}.tar.gz -> ${P}.tar.gz"

DESCRIPTION="A complete toolset for web, mobile and enterprise development"
HOMEPAGE="https://www.jetbrains.com/idea"

LICENSE="IDEA
	|| ( IDEA_Academic IDEA_Classroom IDEA_OpenSource IDEA_Personal )"

DEPEND="
	>=virtual/jdk-1.7:*"

RDEPEND="${DEPEND}
	dev-java/jansi-native
	dev-libs/libdbusmenu
	media-libs/harfbuzz
	"
BDEPEND="dev-util/patchelf"
RESTRICT="splitdebug"
S="${WORKDIR}/${MY_S}"

QA_PREBUILT="opt/${PN}-${PV}/*"

src_unpack() {

	default_src_unpack
	if [ ! -d "$S" ]; then
		einfo "Renaming source directory to predictable name..."
		mv $(ls "${WORKDIR}") "${MY_S}" || die
	fi
}

src_prepare() {

	default_src_prepare

	if use amd64; then
		JRE_DIR=jre64
	else
		JRE_DIR=jre
	fi

	PLUGIN_DIR="${S}/${JRE_DIR}/lib/"

	rm -vf ${PLUGIN_DIR}/libavplugin*
	rm -vf "${S}"/plugins/maven/lib/maven3/lib/jansi-native/*/libjansi*
	rm -vrf "${S}"/lib/pty4j-native/linux/ppc64le
	rm -vf "${S}"/bin/libdbm64*
	rm -vf "${S}"/lib/pty4j-native/linux/mips64el/libpty.so
	rm -vf "${S}"/plugins/cwm-plugin/quiche-native/linux-aarch64/libquiche.so

	if [[ -d "${S}"/"${JRE_DIR}" ]]; then
		for file in "${PLUGIN_DIR}"/{libfxplugins.so,libjfxmedia.so}
		do
			if [[ -f "$file" ]]; then
				patchelf --set-rpath '$ORIGIN' $file || die
			fi
		done
	fi

	patchelf --replace-needed liblldb.so liblldb.so.9 "${S}"/plugins/Kotlin/bin/linux/LLDBFrontend || die "Unable to patch LLDBFrontend for lldb"

	rm -vf "${S}"/lib/pty4j-native/linux/x86-64/libpty.so

	sed -i \
		-e "\$a\\\\" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$a# Disable automatic updates as these are handled through Gentoo's" \
		-e "\$a# package manager. See bug #704494" \
		-e "\$a#-----------------------------------------------------------------------" \
		-e "\$aide.no.platform.update=Gentoo"  bin/idea.properties

	eapply_user
}

src_install() {
	local dir="/opt/${PN}-${MY_PV}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/{format.sh,idea.sh,inspect.sh,restart.py,fsnotifier}
	if use amd64; then
		JRE_DIR=jre64
	else
		JRE_DIR=jre
	fi

	JRE_BINARIES="jaotc java javapackager jjs jrunscript keytool pack200 rmid rmiregistry unpack200"
	if [[ -d ${JRE_DIR} ]]; then
		for jrebin in $JRE_BINARIES; do
			fperms 755 "${dir}"/"${JRE_DIR}"/bin/"${jrebin}"
		done
	fi

	# bundled script is always lowercase, and doesn't have -ultimate, -professional suffix.
	local bundled_script_name="${PN%-*}.sh"
	make_wrapper "${PN}" "${dir}/bin/$bundled_script_name" || die

	local pngfile="$(find ${dst}/bin -maxdepth 1 -iname '*.png')"
	newicon $pngfile "${PN}.png" || die "we died"

	make_desktop_entry "${PN}" "IntelliJ Idea Ultimate" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	mkdir -p "${D}/etc/sysctl.d/" || die
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die

	# remove bundled harfbuzz
	rm -f "${D}"/lib/libharfbuzz.so || die "Unable to remove bundled harfbuzz"

}
