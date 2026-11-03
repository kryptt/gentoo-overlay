# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit python-any-r1

# Firmware images that sys-kernel/gpu-unlock loads with request_firmware().
# They are extracted, unchanged, from NVIDIA's 610.43.03 driver package and
# source archive by the scripts in the upstream repository. Nothing here is
# built per kernel, which is why it is not part of sys-kernel/gpu-unlock.
#
# Keep MY_COMMIT in lockstep with sys-kernel/gpu-unlock, and NV with whatever
# NVIDIA version that commit pins (upstream Makefile: NV := ...).
MY_COMMIT="7eb51bccae0a0b7e599e084d971170e9a1e82d0c"
NV="610.43.03"
NV_SRC="NVIDIA-kernel-module-source-${NV}"
NV_RUN="NVIDIA-Linux-x86_64-${NV}-no-compat32.run"

DESCRIPTION="NVIDIA GSP and booter firmware images used by gpu-unlock, extracted from NVIDIA ${NV}"
HOMEPAGE="https://github.com/Zagitta/gpu-unlock"
SRC_URI="
	https://github.com/Zagitta/gpu-unlock/archive/${MY_COMMIT}.tar.gz -> gpu-unlock-${PV}.tar.gz
	https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/${NV_SRC}.tar.xz
	https://download.nvidia.com/XFree86/Linux-x86_64/${NV}/${NV_RUN}
"
S="${WORKDIR}/gpu-unlock-${MY_COMMIT}"

# The firmware is covered by the NVIDIA driver licence, which does not allow
# redistributing it from here, so users fetch it from NVIDIA themselves.
LICENSE="NVIDIA-r2 MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

BDEPEND="
	${PYTHON_DEPS}
	app-arch/zstd
"

FIRMWARE_FILES=(
	booter_load_ad102.bin booter_load_ga102.bin gsp_boot_ad102.bin gsp_boot_desc_ad102.bin
	booter_load_tu102.bin gsp_boot_tu102.bin gsp_boot_desc_tu102.bin sec2_bl_tu102.bin
	booter_load_ga100.bin falcon_loader.bin gsp_ga10x.bin gsp_tu10x.bin
	gsp_boot_ga102.bin gsp_boot_desc_ga102.bin
	gsp_boot_ga100.bin gsp_boot_desc_ga100.bin
)

src_unpack() {
	unpack "gpu-unlock-${PV}.tar.gz"

	# the .run installer is read in place by extract_gsp.py, never executed
	mkdir "${S}/assets.src" || die
	cd "${S}/assets.src" || die
	unpack "${NV_SRC}.tar.xz"
}

src_compile() {
	mkdir assets || die
	"${EPYTHON}" firmware/extract_gsp.py "${DISTDIR}/${NV_RUN}" assets || die
	"${EPYTHON}" firmware/extract_boot_assets.py "assets.src/${NV_SRC}" assets || die

	local f
	for f in "${FIRMWARE_FILES[@]}" NVIDIA-LICENSE; do
		[[ -s assets/${f} ]] || die "extraction did not produce ${f}"
	done
}

src_install() {
	local f
	insinto "/usr/lib/firmware/gpu-unlock/${NV}"
	for f in "${FIRMWARE_FILES[@]}"; do
		doins "assets/${f}"
	done

	dodoc assets/NVIDIA-LICENSE firmware/NOTICE.md
}
