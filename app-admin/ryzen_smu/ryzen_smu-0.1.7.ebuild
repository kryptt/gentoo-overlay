# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

# This packages a FORK, not the upstream ::gentoo packages as 0.1.5.
#
# gitlab.com/leogx9r/ryzen_smu has been dead since 2022-12-16 and its
# smu_resolve_cpu_class() dispatches only on CPU families 0x17 and 0x19, so it
# cannot bind Strix Halo (family 0x1A, model 0x70) — the module loads and then
# fails probe with -ENODEV. github.com/amkillam/ryzen_smu continues development
# and adds family 0x1A (Strix Point 0x24/0x60, Granite Ridge 0x44, Strix Halo
# 0x70).
#
# Why this matters here: on a Secure Boot node with lockdown [integrity],
# ryzenadj cannot reach the SMU through /dev/mem ("PCI Bus is not writeable").
# This module is the only lockdown-safe interface, and without it the SMU Tctl
# temperature limit silently stops being applied.
#
# CAUTION: if ::gentoo ever ships a version above 0.1.7, portage will prefer it
# and quietly lose family 0x1A support again. Bump this ebuild past it.
MY_COMMIT="1be4fb1cd9d60b5ddefc2a4201a898766a731400"

DESCRIPTION="Kernel driver for AMD Ryzen's System Management Unit (Zen5/Strix Halo fork)"
HOMEPAGE="https://github.com/amkillam/ryzen_smu"
SRC_URI="https://github.com/amkillam/${PN}/archive/${MY_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${MY_COMMIT}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

src_compile() {
	local modlist=( ryzen_smu )
	local modargs=( KERNEL_BUILD="${KV_OUT_DIR}" )

	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install

	insinto /usr/lib/modules-load.d
	doins "${FILESDIR}"/ryzen_smu.conf
}
