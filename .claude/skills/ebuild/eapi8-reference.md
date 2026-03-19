# EAPI 8 Quick Reference

## Key Features (over EAPI 7)
- Bash 5.0 (nameref, negative subscripts, `local -`)
- `IDEPEND` variable (install-time deps for pkg_preinst/pkg_postinst)
- `PROPERTIES` and `RESTRICT` accumulated across eclasses
- `dosym -r` for relative symlinks
- `econf` passes `--datarootdir` and `--disable-static` automatically
- `usev` accepts second argument: `usev flag "--enable-foo"`
- `hasq`, `hasv`, `useq` banned

## Variables

### Metadata
| Variable | Purpose | Notes |
|---|---|---|
| `EAPI` | Package manager API version | Always `8` for new ebuilds. First non-comment line. |
| `DESCRIPTION` | One-line description | Max 80 chars |
| `HOMEPAGE` | Upstream URL | HTTPS preferred |
| `SRC_URI` | Source tarball URLs | Supports `-> rename`, USE conditionals, `fetch+`/`mirror+` |
| `LICENSE` | License identifier(s) | Must match files in `licenses/`. For Rust/Go include dep licenses. |
| `SLOT` | Package slot | `"0"` when no slotting. Format: `SLOT/SUBSLOT` for soname tracking. |
| `KEYWORDS` | Architecture keywords | `~amd64` for testing. Omit entirely for live ebuilds. |
| `IUSE` | USE flag declarations | `+flag` for default-on. |
| `REQUIRED_USE` | USE flag constraints | Use sparingly. Operators: `||`, `^^`, `??`, `flag? ( )` |
| `RESTRICT` | Restrictions | `mirror`, `strip`, `test`, `!test? ( test )` |
| `PROPERTIES` | Package properties | `live` for VCS ebuilds |

### Dependencies
| Variable | Runs on | Purpose | Example |
|---|---|---|---|
| `BDEPEND` | CBUILD | Build tools | compilers, pkg-config, code generators |
| `DEPEND` | CHOST | Compile-time libraries | headers, .so for linking |
| `RDEPEND` | CHOST | Runtime | shared libs, interpreters, data |
| `PDEPEND` | CHOST | Post-merge | Only for circular dep resolution |
| `IDEPEND` | ROOT | Install-time (EAPI 8) | Tools for pkg_postinst |

### Path Variables
| Variable | Value |
|---|---|
| `S` | Source directory (default: `${WORKDIR}/${P}`) |
| `D` | Image directory (install destination) |
| `ED` | `${D%/}${EPREFIX}/` |
| `FILESDIR` | `files/` subdirectory of package dir |
| `WORKDIR` | Temporary work directory |
| `T` | Temporary directory for the ebuild |

## Dependency Syntax

### Version operators
- `>=cat/pkg-1.0` — 1.0 or later
- `~cat/pkg-1.0` — any revision of 1.0
- `=cat/pkg-1.0*` — any 1.0.x (glob)

### Slot operators
- `:=` — any slot, rebuild on slot/subslot change (most common for libs)
- `:*` — any slot, never rebuild
- `:0` — must be in slot 0
- `:0=` — slot 0, rebuild on subslot change

### USE-conditional
```bash
flag? ( cat/pkg )           # if flag enabled
!flag? ( cat/pkg )          # if flag disabled
cat/pkg[flag]               # require flag on dep
cat/pkg[flag=]              # match local flag state
```

### Blockers
```bash
!cat/pkg                    # weak (auto-resolved)
!!cat/pkg                   # strong (must resolve first)
```

## Phase Functions

All phases run in order. Only override when the default is insufficient.

### pkg_pretend
Early sanity checks. Runs before deps installed. No env propagation.

### pkg_setup
Post-dep setup. User/group creation, environment variables.

### src_unpack
Default: `unpack ${A}`. Override for non-standard archives.

### src_prepare
Default: applies `PATCHES` array + `eapply_user`. **Always call `default`.**
```bash
PATCHES=( "${FILESDIR}/${P}-fix.patch" )
src_prepare() {
	default
	# additional work
}
```

### src_configure
Build system configuration.
```bash
# Autotools:
econf $(use_enable foo) $(use_with bar)

# CMake:
local mycmakeargs=( -DENABLE_FOO=$(usex foo) )
cmake_src_configure

# Meson:
local emesonargs=( $(meson_feature foo) )
meson_src_configure
```

### src_compile
Default: `emake`. Override for custom build commands.

### src_test
Default: `emake check` or `emake test`. Guard test deps:
```bash
IUSE="test"
RESTRICT="!test? ( test )"
BDEPEND="test? ( dev-util/test-framework )"
```

### src_install
Install to `${D}`. Key helpers:
| Function | Purpose |
|---|---|
| `dobin` | Install to /usr/bin |
| `dosbin` | Install to /usr/sbin |
| `dolib.so` | Install shared library |
| `doins` | Install general file (respects `insinto`) |
| `dodoc` | Install documentation |
| `doman` | Install man page |
| `dodir` | Create directory |
| `dosym` | Create symlink (`-r` for relative in EAPI 8) |
| `newbin` | Install renamed binary |
| `insinto` | Set install destination for `doins` |
| `exeinto` | Set install destination for `doexe` |
| `keepdir` | Create directory with .keep file |
| `fperms` | Set permissions on installed file |
| `newinitd` | Install OpenRC init script |
| `newconfd` | Install OpenRC config |

### pkg_postinst
Post-install messages. Use `elog` for important info, `optfeature` for optional deps:
```bash
pkg_postinst() {
	elog "Run 'foo --setup' to configure."
	optfeature "GUI support" x11-libs/gtk+:3
}
```

## USE Flag Helpers
```bash
use flag              # returns 0 if enabled
usev flag             # echoes "flag" if enabled
usev flag "value"     # echoes "value" if enabled (EAPI 8)
usex flag "yes" "no"  # echoes yes/no based on flag
use_enable flag       # --enable-flag / --disable-flag
use_enable flag name  # --enable-name / --disable-name
use_with flag         # --with-flag / --without-flag
```

## Version Manipulation (EAPI 7+)
```bash
ver_cut 1      ${PV}  # major version
ver_cut 1-2    ${PV}  # major.minor
ver_rs 2 '-'  ${PV}   # replace 2nd separator: 1.2.3 -> 1.2-3
ver_test 1.2 -gt 1.1  # version comparison
```
