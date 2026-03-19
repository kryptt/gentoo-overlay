# Ebuild QA Checklist

Run through this checklist before finalizing any ebuild.

## File Format
- [ ] Copyright header: `# Copyright 2026 Gentoo Authors` (current year)
- [ ] License header: `# Distributed under the terms of the GNU General Public License v2`
- [ ] `EAPI=8` is the first non-comment, non-blank line
- [ ] Tabs for all indentation (no spaces)
- [ ] No trailing whitespace
- [ ] No lines over ~120 chars (prefer under 80)
- [ ] UTF-8 encoding
- [ ] Empty line before each phase function

## Variables
- [ ] `DESCRIPTION` is under 80 characters
- [ ] `HOMEPAGE` uses HTTPS
- [ ] `SRC_URI` uses variables (`${P}`, `${PV}`) not hardcoded versions
- [ ] `LICENSE` matches upstream license exactly
- [ ] `SLOT` is set (use `"0"` if no slotting needed)
- [ ] `KEYWORDS` present for release ebuilds, absent for live
- [ ] `S` only set if different from default `${WORKDIR}/${P}`
- [ ] No redefinition of `P`, `PV`, `PN`, `PF` (use `MY_P`, `MY_PV`, `MY_PN`)
- [ ] Variable order follows devmanual convention

## Dependencies
- [ ] `BDEPEND` for build-host tools (pkg-config, generators, compilers)
- [ ] `DEPEND` for compile-time CHOST libraries
- [ ] `RDEPEND` for runtime dependencies
- [ ] `virtual/pkgconfig` in BDEPEND if pkg-config is used
- [ ] `:=` slot operator on library dependencies
- [ ] Full category/package in all deps (not just package name)
- [ ] No `:=` inside `|| ( )` groups
- [ ] Test deps guarded: `RESTRICT="!test? ( test )"` + `BDEPEND="test? ( ... )"`
- [ ] No deps on meta-packages

## USE Flags
- [ ] All flags in `IUSE` are actually used in the ebuild
- [ ] All used `use*` calls reference flags in `IUSE`
- [ ] Local USE flags documented in `metadata.xml`
- [ ] `REQUIRED_USE` used sparingly and only when necessary
- [ ] No USE flags for unconditionally useful small files

## Phase Functions
- [ ] `src_prepare` calls `default` (or is not overridden)
- [ ] Every external command has `|| die`
- [ ] No use of `ROOT` in `src_*` phases
- [ ] `emake` instead of raw `make`
- [ ] `econf` for autotools configure
- [ ] `tc-getCC` / `tc-export` for compiler references (not hardcoded `gcc`)
- [ ] No `-Werror` in build flags
- [ ] Phase functions in correct order

## Eclasses
- [ ] All inherited eclasses are actually used
- [ ] Pre-inherit variables set before `inherit` line
- [ ] Eclass phase functions called correctly (e.g., `cmake_src_configure`)

## Files
- [ ] Patches in `files/` are under 20 KiB each
- [ ] Patch naming: `${P}-description.patch`
- [ ] `metadata.xml` exists with maintainer info
- [ ] `metadata.xml` uses tabs for indentation
- [ ] `metadata.xml` has `<upstream>` with `<remote-id>`
- [ ] Manifest is generated and up-to-date

## Automated Checks
```bash
# Run pkgcheck on the package
pkgcheck scan category/package

# Run with network checks
pkgcheck scan --net category/package

# Test the build
ebuild path/to/ebuild.ebuild clean manifest install

# Full emerge test
emerge -pv category/package
emerge -1v category/package
```

## Common Mistakes to Avoid
1. Missing `|| die` on commands that can fail
2. Forgetting `default` in `src_prepare`
3. Using spaces instead of tabs
4. Hardcoding paths or versions
5. Wrong dependency category (BDEPEND vs DEPEND vs RDEPEND)
6. Leaving `-Werror` in upstream build system
7. Not including licenses for statically linked Rust/Go deps
8. Setting `S` to the default value redundantly
9. Using deprecated functions (hasq, useq, dohtml, dolib)
10. Missing slot operators on library deps
