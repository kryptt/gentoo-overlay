# Eclass Quick Reference

## Build System Eclasses

### cmake
```bash
inherit cmake

src_configure() {
	local mycmakeargs=(
		-DENABLE_FEATURE=$(usex feature)
		-DBUILD_TESTS=$(usex test)
		$(cmake_use_find_package gui Qt5)
	)
	cmake_src_configure
}
# cmake_src_compile and cmake_src_install called automatically
```

### meson
```bash
inherit meson

src_configure() {
	local emesonargs=(
		$(meson_use qt5)
		$(meson_feature threads)
		-Doptional_thing=$(usex thing enabled disabled)
	)
	meson_src_configure
}
```

### cargo (Rust)
```bash
# BEFORE inherit:
CRATES="
	serde@1.0.160
	tokio@1.28.0
"
inherit cargo

SRC_URI="
	https://example.com/${P}.tar.gz
	${CARGO_CRATE_URIS}
"
# LICENSE must include all crate licenses
LICENSE="MIT Apache-2.0 BSD"

src_configure() {
	local myfeatures=( feature1 )
	use ssl && myfeatures+=( tls )
	cargo_src_configure
}
```
Generate CRATES with: `pycargoebuild <path-to-Cargo.lock>`

### go-module (Go)
```bash
# Two approaches:

# 1. Vendored deps (if upstream vendors)
inherit go-module
SRC_URI="https://example.com/${P}.tar.gz"

# 2. Dependency tarball (preferred)
EGO_SUM=( ... )  # or use a deps tarball
inherit go-module
SRC_URI="
	https://example.com/${P}.tar.gz
	https://example.com/${P}-deps.tar.xz
"

src_compile() {
	ego build ./cmd/myapp
}
src_install() {
	dobin myapp
}
```
Use `ego` instead of `go`. Include all dep licenses in LICENSE.

### autotools
```bash
inherit autotools

src_prepare() {
	default
	eautoreconf  # only if patching configure.ac or Makefile.am
}
```

## Language Eclasses

### distutils-r1 (Python, PyPI)
```bash
PYTHON_COMPAT=( python3_{11..13} )
DISTUTILS_USE_PEP517=setuptools  # or: flit, hatchling, poetry, meson-python
inherit distutils-r1

# Tests:
distutils_enable_tests pytest
# adds IUSE=test, RESTRICT, BDEPEND automatically
```

### python-single-r1
For packages needing exactly one Python (non-pure-Python tools):
```bash
PYTHON_COMPAT=( python3_{11..13} )
inherit python-single-r1
REQUIRED_USE="${PYTHON_SINGLE_USEDEP}"
RDEPEND="$(python_gen_cond_dep 'dev-python/foo[${PYTHON_USEDEP}]')"
```

### python-any-r1
When Python is only needed at build time:
```bash
PYTHON_COMPAT=( python3_{11..13} )
inherit python-any-r1
BDEPEND="${PYTHON_DEPS}"
```

## VCS Eclasses

### git-r3 (live git ebuilds)
```bash
inherit git-r3
EGIT_REPO_URI="https://github.com/user/repo.git"
# Optional:
EGIT_BRANCH="develop"
EGIT_COMMIT="abc123"
# No KEYWORDS, no SRC_URI
```

## Utility Eclasses

### toolchain-funcs
Cross-compilation correctness:
```bash
inherit toolchain-funcs
src_compile() {
	tc-export CC CXX PKG_CONFIG
	emake CC="$(tc-getCC)"
}
```

### linux-info
Kernel config checks:
```bash
inherit linux-info
CONFIG_CHECK="~DRM ~FB"
pkg_setup() {
	linux-info_pkg_setup
}
```

### systemd
```bash
inherit systemd
src_install() {
	default
	systemd_dounit "${FILESDIR}/${PN}.service"
	systemd_newunit "${FILESDIR}/${PN}.service.in" "${PN}@.service"
}
```

### udev
```bash
inherit udev
src_install() {
	default
	udev_dorules "${FILESDIR}/99-${PN}.rules"
}
pkg_postinst() {
	udev_reload
}
```

### optfeature
```bash
inherit optfeature
pkg_postinst() {
	optfeature "PDF support" app-text/poppler
	optfeature "spell checking" app-text/aspell
}
```

### wrapper
```bash
inherit wrapper
src_install() {
	# Create wrapper script that sets LD_LIBRARY_PATH etc.
	make_wrapper myapp /opt/myapp/bin/myapp /opt/myapp /opt/myapp/lib
}
```

### xdg
For packages installing .desktop files, icons, or mime types:
```bash
inherit xdg
# Automatically updates icon cache, desktop database, mime database
```

### desktop
```bash
inherit desktop
src_install() {
	default
	make_desktop_entry myapp "My App" myapp "Utility;"
	doicon "${FILESDIR}/myapp.png"
}
```

## Eclass Combinations

Common combinations:
- `cmake xdg` — CMake GUI app
- `cargo xdg` — Rust GUI app
- `python-single-r1 cmake` — C++ project with Python bindings
- `git-r3 cmake` — Live CMake project
- `git-r3 cargo` — Live Rust project
