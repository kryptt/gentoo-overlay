# AMD XDNA2 / AIE-ML (Ryzen AI NPU) Compiler Toolchain on Gentoo

Research + packaging plan. Target box: **rh-anine** (Ryzen AI Max+ 395, Strix Halo,
gfx1151, XDNA2 NPU = `aie2p`), kernel 6.18-gentoo, `/dev/accel0`, `amdxdna` loaded.

Date: 2026-07-10.

## TL;DR

The **runtime** half of the stack is already packaged in the **GURU** overlay and
installed on this box. The **compiler** half (Peano + MLIR-AIE/IRON) is *not*
packaged anywhere (::gentoo or ::guru). This overlay adds it.

Upstream ships the compiler as **prebuilt wheels**, and building the LLVM fork from
source buys nothing (it's just a full clang+lld+backend compile of an *unreleased*
commit). So both new ebuilds **repackage the prebuilt wheels** rather than compile.

## What already exists

### GURU overlay (`/var/db/repos/guru`) — runtime, DONE, installed here

| Package | Version installed | Provides |
|---|---|---|
| `dev-util/xrt` | 2.21.75 | XRT runtime, `/usr/bin/xrt-smi` (owner confirmed via qfile) |
| `dev-libs/xrt-xdna` | 2.21.75-r1 | XDNA shim/plugin for XRT (`AMD-Binary-Only` VTD blobs) |
| `dev-libs/xdna-driver` | 2.21.75-r2 | out-of-tree `amdxdna.ko` + NPU firmware (`/lib/firmware/amdnpu`) |

Maintainer: Sv. Lockal `<lockalsash@gmail.com>`. These are solid, upstream-tracking
ebuilds (submodule pinning, VTD hash sanity checks). We depend on `dev-util/xrt`
from `mlir-aie` and otherwise leave them alone.

Gentoo wiki reference: **User:Lockal/AMDXDNA**
(https://wiki.gentoo.org/wiki/User:Lockal/AMDXDNA). It explicitly notes Peano "is not
packaged in ::guru" and recommends `pip install` of the prebuilt wheel — i.e. there
is no prior art for the compiler pieces; this overlay is the first.

### ::gentoo — generic LLVM only

`llvm-core/llvm` up to 22/23 and `llvm-core/mlir` up to 22/23 exist, but they are
**useless for AIE**: MLIR-AIE pins a *specific* upstream `llvm/llvm-project` commit
for its MLIR dialect build, and Peano is a *separate* AMD LLVM fork with an `AIE`
backend target that stock LLVM does not have. Neither can be satisfied by the
in-tree LLVM.

## What's missing (this overlay adds it)

1. **`dev-util/llvm-aie` (Peano)** — the LLVM/clang/lld fork with the `AIE` backend
   (targets `aie2` = XDNA1 Phoenix/Hawk, `aie2p` = XDNA2 Strix — *our* hardware).
   The chess-free backend: no proprietary `xchesscc`/Vitis needed for AIE2/AIE2P.
2. **`dev-util/mlir-aie` (IRON)** — the MLIR-based dataflow compiler + the IRON
   Python API (`import aie`) used to author and build NPU kernels. Consumes Peano.

## Distribution model & version pins (the hard part)

### Peano / llvm-aie — https://github.com/Xilinx/llvm-aie

- **No tagged releases.** Only a rolling `nightly` GitHub release that is
  continuously overwritten, plus one stale `nightly-*` tag. Upstream deliberately
  has no release procedure.
- pip index (find-links): `https://github.com/Xilinx/llvm-aie/releases/expanded_assets/nightly`
- Install: `pip install llvm-aie -f <that index>`
- Wheel name: `llvm_aie-<llvmbase>.<datestamp>+<shorthash>-py3-none-<platform>.whl`
  e.g. `llvm_aie-21.0.0.2026070801+4fb2354f-py3-none-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl`
- **`py3-none` ABI tag → Python-version-agnostic.** The wheel is just prebuilt
  native `clang`/`lld` + AIE runtime libs zipped up. One wheel works for any Python.
- Platforms: linux `manylinux_2_27/2_28` x86_64 (~138 MB), win_amd64. **No arm64.**
- Install layout: payload folder `llvm-aie/` (bin/, lib/, ...). `mlir-aie`'s
  `env_setup.sh` sets `PEANO_INSTALL_DIR = <site-packages>/llvm-aie` (dir with
  `bin/clang`) and passes it to `aiecc.py` via `--peano` — deliberately **not** on
  `PATH` (avoids clobbering the system clang).
- **Source build = not worth it**: standard LLVM cmake with
  `-DLLVM_TARGETS_TO_BUILD="X86;AIE" -DLLVM_ENABLE_PROJECTS="clang;lld"` + AIE
  runtimes — tens of GB, ~1h+, and you'd still be pinning an unreleased fork commit
  by hand. The wheel is the intended channel.

### MLIR-AIE / IRON — https://github.com/Xilinx/mlir-aie

- Latest release: **`v1.3.4`** (2026-07-02). Python API layer = **IRON**.
- Publishes **prebuilt `mlir_aie` wheels**, CPython-ABI-specific:
  - pinned: `pip install mlir_aie -f https://github.com/Xilinx/mlir-aie/releases/expanded_assets/v1.3.4`
  - rolling: `...expanded_assets/latest-wheels-4`
  - Python **3.11, 3.12, 3.13, 3.14**; wheels `mlir_aie-1.3.4-cpXXX-cpXXX-manylinux_2_35_x86_64.whl` (~232 MB each).
- **LLVM/MLIR pin** (`utils/clone-llvm.sh`): `llvm/llvm-project` commit
  `068c6c5c0c8a0555036a2ff09a99f486548e6e8d` (dated 2026-06-01). Relevant only to
  a *source* build of the dialect — the wheel bakes it in.
- **Peano pin** (`utils/peano-requirements.txt`): `llvm-aie==21.0.0.2026070801+4fb2354f`
  from the nightly index. Auto-bumped by upstream's `update-peano` CI. **This is the
  CI-tested pairing** — our `mlir-aie` ebuild pins the matching `dev-util/llvm-aie`.
- Vitis / `xchesscc`: **NOT required** for AIE2/AIE2P (Peano-only path). Vitis is
  legacy AIE1 only.
- **XRT required at runtime** for on-device execution (`xrt-smi` etc. on PATH).
  Needs kernel ≥ 6.17 + `amdxdna` driver — both satisfied on rh-anine (6.18 +
  GURU `xdna-driver`).
- Caveat: the packaged `pyxrt` (in-process XRT python binding) supports **Python
  3.12 only**. mlir_aie wheels span 3.11–3.14, but if you want `pyxrt`, use 3.12.

### Compatibility matrix (the pins *are* the contract; no human-readable matrix)

| mlir-aie | LLVM base commit (dialect) | Peano wheel | XRT |
|---|---|---|---|
| v1.3.4 (Jul 2026) | 068c6c5c...e6e8d (2026-06-01) | 21.0.0.2026070801+4fb2354f | 2.21.x (GURU: 2.21.75) |

Per-tag: check out the mlir-aie tag and read `utils/peano-requirements.txt`
(Peano) + `utils/clone-llvm.sh` (LLVM base). Treat **mlir-aie tag ⇒ its Peano
wheel** as one coupled bump, mirroring upstream `update-peano`.

## Packaging plan (order = dependency order)

1. **`dev-util/llvm-aie-21.0.0.2026070801`** — repackage the `py3-none` linux wheel.
   Unzip, relocate the `llvm-aie/` payload under `/usr/lib/llvm-aie`, expose
   `PEANO_INSTALL_DIR` via `/etc/env.d`. `QA_PREBUILT` + `RESTRICT="strip"`.
   `KEYWORDS="~amd64"` (no arm64 wheel). No python eclass needed — pure binaries.
2. **`dev-util/mlir-aie-1.3.4`** — repackage the per-CPython `mlir_aie` wheel with
   `python-single-r1` (USE-conditional `SRC_URI` per `PYTHON_SINGLE_TARGET`). Unzip
   the matching wheel into the site-packages dir, install `bin/` tools, expose
   `MLIR_AIE_INSTALL_DIR`. `RDEPEND`: `~dev-util/llvm-aie-<pin>`, `dev-util/xrt`,
   the python runtime. `KEYWORDS="~amd64"`.
   - **`PYTHON_COMPAT=( python3_{12..14} )`**: upstream ships cp311..cp314 wheels,
     but Gentoo's `python3_11` is *historical* as of 2026 (current impls are
     3.12–3.15), so referencing a `python_single_target_python3_11` flag is a
     metadata error ("not in IUSE"). We target the 3.12–3.14 overlap; `python3_15`
     has no upstream wheel. (Verified: `ebuild ... help` metadata sourcing is clean
     with 3.12–3.14, errors with 3.11.)

Category choice: **`dev-util/`** for both, to sit alongside GURU's `dev-util/xrt`
and keep the whole XDNA/AIE stack discoverable in one place. (mlir-aie also ships an
`import aie` python module, but it is fundamentally a compiler toolchain, so
`dev-util` over `dev-python`.)

## Blockers / gotchas encoded in the ebuilds

1. **Ephemeral SRC_URI (the big one).** The Peano `nightly` release deletes old
   assets as it rolls, so `SRC_URI` for a specific dated wheel *will* 404 within days
   of publication. We pin the exact CI-matched wheel anyway (correctness), set
   `RESTRICT="mirror"`, and document that the user must fetch the wheel while it's
   live (or we host it on the internal registry / distfiles mirror). This is the
   fundamental reason Lockal did not package it in GURU. **TODO:** mirror the pinned
   wheels to `registry.hr-home.xyz` / a local distfiles server for durability.
2. **No upstream semver** — versions are `datestamp+hash`. Bump mlir-aie and its
   pinned Peano together.
3. **`pyxrt` = Python 3.12 only** — documented; on-device python bindings want 3.12.
4. **No arm64** — `~amd64` only.
5. **Manifest**: wheels are 138–232 MB binaries; `RESTRICT="mirror"` + BDEPEND
   unzip. Manifest DIST hashes must be generated against the live asset
   (`ebuild ... manifest`) before use — left as a TODO where the asset had rolled.

## Verification done

- `qfile /usr/bin/xrt-smi` → `dev-util/xrt` (GURU).
- `lsmod | grep xdna` → `amdxdna` loaded; `/dev/accel0` present (render group).
- Searched all 18 installed repos: only GURU has xrt/xdna-driver/xrt-xdna; **no**
  repo has llvm-aie or mlir-aie.
- Confirmed exact wheel filenames/URLs from the GitHub `expanded_assets` pages.
