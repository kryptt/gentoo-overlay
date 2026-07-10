# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# AMD/Xilinx "Peano" — an LLVM/clang/lld fork carrying the AI Engine (AIE)
# backend targets: aie, aie2 (XDNA1 Phoenix/Hawk), aie2p (XDNA2 Strix),
# aie2ps. This is the chess-free backend: no proprietary xchesscc / Vitis is
# needed to build kernels for AIE2/AIE2P. It is the compiler that
# dev-util/mlir-aie (IRON) drives via PEANO_INSTALL_DIR.
#
# Upstream ships ONLY prebuilt wheels (no source releases, no stable tags):
# a rolling `nightly` GitHub release that is continuously overwritten. The
# wheel is `py3-none` (Python-version-agnostic) — it is simply a zip of
# prebuilt native clang/lld/llvm binaries + AIE runtime libs. So we repackage
# the wheel rather than compile the LLVM fork from source (which buys nothing
# and takes an hour+).
#
# BLOCKER: because the `nightly` release deletes old assets as it rolls, the
# SRC_URI below WILL 404 within days of publication. This exact wheel
# (21.0.0.2026070801+4fb2354f) is the version pinned by mlir-aie v1.3.4's
# utils/peano-requirements.txt (the CI-tested pairing). RESTRICT=mirror is set;
# fetch the wheel while it is live, or host it on a local distfiles mirror.
# TODO: mirror pinned Peano wheels to registry.hr-home.xyz / a distfiles server.

DESCRIPTION="AMD/Xilinx Peano: LLVM/clang/lld fork with the AI Engine (AIE) backend"
HOMEPAGE="https://github.com/Xilinx/llvm-aie"

# Build metadata hash from the wheel version (21.0.0.2026070801+<PEANO_HASH>).
# Gentoo PV cannot contain '+', so the hash lives here and PV holds the
# LLVM-base.datestamp only.
PEANO_HASH="4fb2354f"
MY_PV="${PV}+${PEANO_HASH}"
WHEEL_PLATFORM="manylinux_2_27_x86_64.manylinux_2_28_x86_64"
WHEEL="llvm_aie-${MY_PV}-py3-none-${WHEEL_PLATFORM}.whl"

SRC_URI="https://github.com/Xilinx/llvm-aie/releases/download/nightly/${WHEEL} -> ${PN}-${PV}_${PEANO_HASH}.whl"
S="${WORKDIR}"

# Apache-2.0 WITH LLVM-exception (it is an LLVM fork).
LICENSE="Apache-2.0-with-LLVM-exceptions"
SLOT="0"
KEYWORDS="~amd64"

# Prebuilt native binaries: no arm64 wheel exists; do not strip; do not mirror
# (ephemeral rolling upstream asset).
RESTRICT="strip mirror"
QA_PREBUILT="usr/lib/llvm-aie/*"

BDEPEND="app-arch/unzip"

# The bundled clang/lld are self-contained via RUNPATH=$ORIGIN/../lib (they
# ship their own libLLVM.so / libclang-cpp.so), so no LLVM RDEPEND is needed.
# glibc + the usual C++ runtime are the only real runtime requirements.
RDEPEND=""

src_unpack() {
	# A wheel is a zip; the payload is a self-contained LLVM install prefix
	# under llvm-aie/ ({bin,include,lib,share}).
	unzip -q "${DISTDIR}/${PN}-${PV}_${PEANO_HASH}.whl" -d "${S}" || die
}

src_install() {
	# Install the whole prefix under /usr/lib/llvm-aie. Keeping bin/ and lib/
	# adjacent preserves the $ORIGIN/../lib RUNPATH so the bundled libLLVM.so
	# resolves without polluting the system library path.
	dodir /usr/lib
	cp -a "${S}/llvm-aie" "${ED}/usr/lib/" || die

	# Peano is intentionally NOT placed on PATH (would shadow the system
	# clang). mlir-aie / aiecc.py locate it via PEANO_INSTALL_DIR and the
	# --peano flag. Export it for the whole system.
	newenvd - 60llvm-aie <<-EOF
		# AMD/Xilinx Peano (dev-util/llvm-aie) — AIE backend clang/lld.
		# Consumed by dev-util/mlir-aie (IRON) via aiecc.py --peano.
		PEANO_INSTALL_DIR=/usr/lib/llvm-aie
	EOF
}

pkg_postinst() {
	elog "Peano (llvm-aie) is installed at /usr/lib/llvm-aie and exported as"
	elog "  PEANO_INSTALL_DIR=/usr/lib/llvm-aie  (via /etc/env.d/60llvm-aie)"
	elog
	elog "It is deliberately NOT on PATH to avoid shadowing the system clang."
	elog "AIE targets available: aie, aie2 (XDNA1), aie2p (XDNA2 Strix), aie2ps."
	elog "Invoke directly, e.g.:"
	elog "  /usr/lib/llvm-aie/bin/clang --target=aie2p-none-unknown-elf ..."
	elog
	elog "This wheel is pinned to match dev-util/mlir-aie's peano-requirements."
	elog "Run 'source /etc/profile' or re-login to pick up PEANO_INSTALL_DIR."
}
