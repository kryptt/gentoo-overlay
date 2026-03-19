---
name: ebuild
description: Create or update Gentoo ebuild packages. Use when the user wants to add a new package, bump a version, write an ebuild, or fix ebuild issues.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch
argument-hint: "[category/package-version] or [upstream URL]"
---

# Gentoo Ebuild Creation Skill

You are an expert Gentoo ebuild developer working in the `rhansen-overlay` overlay.
Always use **EAPI 8** for new ebuilds. Follow the Gentoo devmanual strictly.

## Workflow

When creating or updating an ebuild, follow these steps in order:

### Step 1: Gather Upstream Information

- If given a URL or package name, research the upstream project:
  - Build system (autotools, cmake, meson, cargo, go modules, python setuptools/flit/hatch, etc.)
  - Dependencies (build-time, runtime, test)
  - License
  - Available compile-time options / features
  - Latest stable release version and tarball URL
- Check if the package already exists in the Gentoo main repo or this overlay:
  ```bash
  # In the devcontainer:
  emerge -s <name>
  equery list -po <name> 2>/dev/null
  ```
- Check existing ebuilds in the overlay for patterns to follow:
  ```bash
  find /var/db/repos/rhansen-overlay -name '*.ebuild' | head -20
  ```

### Step 2: Choose the Right Eclass

Select based on the build system. See [eclass-reference.md](eclass-reference.md) for details.

| Build system | Eclass | Key pattern |
|---|---|---|
| CMake | `cmake` | `mycmakeargs=( ... )` |
| Meson | `meson` | `emesonargs=( ... )` |
| Autotools | `autotools` (if patching .ac/.am) | `eautoreconf` in src_prepare |
| Cargo/Rust | `cargo` | Define `CRATES`, `LICENSE` includes deps |
| Go modules | `go-module` | Vendor tarball or vendored source |
| Python (PyPI) | `distutils-r1` | Set `DISTUTILS_USE_PEP517` |
| Python (single) | `python-single-r1` | For tools embedding Python |
| Plain Makefile | (none) | Override src_compile/src_install |
| Pre-built binary | (none) | Use `QA_PREBUILT`, `-bin` suffix |
| Git live | `git-r3` | `EGIT_REPO_URI`, no KEYWORDS |

### Step 3: Design USE Flags

Apply these rules strictly:

**DO create USE flags for:**
- Optional features with external dependencies (e.g., `gui`, `ssl`, `lua`)
- Features with significant build cost
- Features that change installed files materially

**DO NOT create USE flags for:**
- Small always-useful files (bash completions, systemd units, man pages) — install unconditionally
- Compiler flags — users set those in make.conf
- Runtime-only deps that don't affect compiled output

Document all local USE flags in `metadata.xml`.

### Step 4: Write the Ebuild

Follow this exact variable ordering. See [eapi8-reference.md](eapi8-reference.md) for variable and function details.

```bash
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Pre-inherit variables (PYTHON_COMPAT, CRATES, LLVM_COMPAT, etc.)
inherit eclass1 eclass2

DESCRIPTION="Short description (max 80 chars)"
HOMEPAGE="https://upstream.example.com"
SRC_URI="https://example.com/releases/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="flag1 flag2"
# REQUIRED_USE only if truly needed

BDEPEND="
	virtual/pkgconfig
"
DEPEND="
	dev-libs/libfoo:=
	flag1? ( dev-libs/libbar:= )
"
RDEPEND="${DEPEND}"

# Phase functions in execution order, only override when needed
```

**Critical rules:**
- Tabs for indentation, never spaces
- `|| die` after every external command in phase functions
- Always call `default` in overridden phases (especially `src_prepare`)
- Use `${P}`, `${PV}`, `${PN}` — never hardcode versions
- Use `:=` slot operator for library dependencies
- `BDEPEND` for build tools, `DEPEND` for compile-time libs, `RDEPEND` for runtime
- Include `virtual/pkgconfig` in BDEPEND if any pkg-config usage
- Use `tc-getCC`, `tc-getCXX` from `toolchain-funcs` for cross-compilation correctness

### Step 5: Write metadata.xml

Every package directory needs a `metadata.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="person">
		<email>maintainer@example.com</email>
		<name>Maintainer Name</name>
	</maintainer>
	<use>
		<flag name="myflag">Description of what this flag enables</flag>
	</use>
	<upstream>
		<remote-id type="github">user/repo</remote-id>
	</upstream>
</pkgmetadata>
```

Use tabs for indentation. Include `<use>` block only if the ebuild defines local USE flags.

### Step 6: Generate Manifest

```bash
# In the devcontainer:
ebuild /var/db/repos/rhansen-overlay/cat/pkg/pkg-1.0.ebuild manifest
# Or:
cd /var/db/repos/rhansen-overlay/cat/pkg && pkgdev manifest
```

This overlay uses thin manifests (`thin-manifests = true`), so only DIST entries are recorded.

### Step 7: QA Verification

Run these checks in the devcontainer:

```bash
# Lint the package
cd /var/db/repos/rhansen-overlay
pkgcheck scan cat/pkg

# Test the build (as root in devcontainer)
ebuild cat/pkg/pkg-1.0.ebuild clean manifest install

# Full emerge test
emerge -pv cat/pkg
emerge -1v cat/pkg
```

See [qa-checklist.md](qa-checklist.md) for the full QA checklist.

## File Organization

```
category/
└── package-name/
    ├── metadata.xml
    ├── Manifest          (auto-generated, thin)
    ├── package-name-1.0.ebuild
    └── files/
        └── package-name-1.0-fix.patch  (if needed, <20 KiB each)
```

## Special Patterns

### Version Bump
1. Copy the previous ebuild: `cp pkg-1.0.ebuild pkg-1.1.ebuild`
2. Update version-specific items (SRC_URI changes, new deps, removed features)
3. Verify patches still apply
4. Regenerate Manifest
5. Run pkgcheck

### Live Ebuild (9999)
- Inherit `git-r3`, set `EGIT_REPO_URI`
- Omit `KEYWORDS` entirely (do not set empty string)
- Omit `SRC_URI` (VCS eclass handles it)

### Binary Package
- Append `-bin` to package name if a source version exists
- Set `QA_PREBUILT="path/to/binary"` for pre-compiled files
- Consider `RESTRICT="strip mirror"`

### Rust/Cargo
- Use `app-portage/pycargoebuild` to generate CRATES list
- Include all dependency licenses in LICENSE
- Set `QA_FLAGS_IGNORED` if needed for pre-built Rust artifacts

### Go Modules
- Create a dependency tarball or use vendored source
- Include all dependency licenses in LICENSE
- Use `ego` instead of raw `go` commands
