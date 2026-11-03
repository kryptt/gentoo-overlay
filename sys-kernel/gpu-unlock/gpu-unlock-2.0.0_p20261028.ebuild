# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1 systemd

# Unofficial community project (not NVIDIA). Pinned to upstream commit 7eb51bc
# (VERSION 2.0.0, merge of PR #250, 2026-10-28). Keep this and
# sys-firmware/gpu-unlock-firmware on the same commit: the module hard-codes the
# firmware directory name (gpu-unlock/<NVIDIA version>/).
MY_COMMIT="7eb51bccae0a0b7e599e084d971170e9a1e82d0c"

DESCRIPTION="Kernel module that lifts the GeForce half-rate FP16/BF16/TF32 tensor cap before nvidia binds"
HOMEPAGE="https://github.com/Zagitta/gpu-unlock"
SRC_URI="https://github.com/Zagitta/${PN}/archive/${MY_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${MY_COMMIT}"

LICENSE="GPL-2 MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="dist-kernel +systemd"

RDEPEND="
	sys-firmware/gpu-unlock-firmware
	dist-kernel? ( virtual/dist-kernel:= )
"

# upstream dkms.conf: BUILD_EXCLUSIVE_CONFIG="CONFIG_PCI CONFIG_FW_LOADER"
CONFIG_CHECK="PCI FW_LOADER"

src_compile() {
	# Kbuild and a wrapper Makefile live in kernel/gpu_unlock; kbuild picks Kbuild.
	# "extra" matches where the hand-built module was installed before this package.
	local modlist=( gpu_unlock=extra:kernel/gpu_unlock )

	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install

	dodoc README.md
	use systemd && systemd_dounit "${FILESDIR}"/gpu-unlock.service
}

pkg_postinst() {
	linux-mod-r1_pkg_postinst

	elog "gpu_unlock does nothing unless the kernel command line opts in:"
	elog "    gpu_unlock.targets=0000:41:00.0   (full PCI name from 'lspci -D', or 'all')"
	elog
	elog "It has to run BEFORE the nvidia driver binds the card. A softdep cannot do that:"
	elog "nvidia.ko ships its own 'softdep nvidia pre:' and kmod honours only the first one."
	elog "A pattern that works without an initramfs:"
	elog "    modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm   (kernel command line)"
	elog "    systemctl enable gpu-unlock.service   (loads gpu_unlock first, then nvidia by name)"
	elog
	elog "This module is built per kernel. After every kernel build run:"
	elog "    emerge @module-rebuild"
	elog "and do it BEFORE rebooting into that kernel."
}
