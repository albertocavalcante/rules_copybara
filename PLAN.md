# rules_copybara - Implementation Plan

Bazel rules for running [Copybara](https://github.com/google/copybara) workflows.

## Design Principles

1. **Cross-platform** - No shell scripts; works on Linux, macOS, and Windows natively
2. **Bzlmod-only** - No WORKSPACE support; modern Bazel only
3. **Airgap-friendly** - Users can override copybara source via MODULE.bazel
4. **Simple API** - Validate, run, and migrate rules with sensible defaults

## Architecture

### Cross-Platform Approach: Java Launcher

Instead of shell scripts (which break on Windows), we use a Java launcher:

```
┌─────────────────────────────────────────────────────────────┐
│                     copybara_migrate                        │
├─────────────────────────────────────────────────────────────┤
│  1. Generate .args file with preset arguments               │
│  2. Set COPYBARA_ARGS_FILE env var                          │
│  3. Execute Java launcher (cross-platform via java_binary)  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   CopybaraLauncher.java                     │
├─────────────────────────────────────────────────────────────┤
│  1. Read args from COPYBARA_ARGS_FILE                       │
│  2. Append any CLI args passed after --                     │
│  3. Call com.google.copybara.Main.main(args)                │
└─────────────────────────────────────────────────────────────┘
```

Why Java launcher:
- `java_binary` creates native launchers for all platforms (including `.bat` on Windows)
- No shell escaping issues
- Copybara already requires Java 21+, so no new dependencies
- Single code path for all platforms

### Airgap Support

Users override copybara source in their MODULE.bazel:

```starlark
# Option 1: Internal mirror
bazel_dep(name = "copybara", version = "0.0.0-20250728-6672ce2")
archive_override(
    module_name = "copybara",
    urls = ["https://artifactory.internal/copybara.tar.gz"],
    integrity = "sha256-...",
)

# Option 2: Local path
local_path_override(
    module_name = "copybara",
    path = "/path/to/local/copybara",
)
```

## Implementation Status

### Completed

- [x] `MODULE.bazel` - Bzlmod configuration with copybara from BCR
- [x] `copybara_validate` - Validates config at build time
- [x] `copybara_run` - Generic runner (pass args after --)
- [x] `copybara_migrate` - Preset workflow runner via Java launcher
- [x] `copybara` macro - Convenience wrapper creating all targets
- [x] `CopybaraInfo` provider
- [x] Java launcher (`CopybaraLauncher.java`)
- [x] Example (`examples/basic/`)
- [x] Test structure (`tests/`)

### Pending

- [ ] CI setup (GitHub Actions for Linux/macOS/Windows)
- [ ] Integration tests
- [ ] BCR submission
- [ ] Documentation site

## File Structure

```
rules_copybara/
├── MODULE.bazel                    # Bzlmod config
├── BUILD.bazel                     # Root BUILD
├── copybara.bzl                    # Public API
├── private/
│   ├── BUILD.bazel
│   ├── providers.bzl               # CopybaraInfo
│   ├── copybara_validate.bzl       # Validate rule
│   ├── copybara_run.bzl            # Generic runner
│   ├── copybara_migrate.bzl        # Migrate rule
│   └── launcher/
│       ├── BUILD.bazel
│       └── CopybaraLauncher.java   # Cross-platform launcher
├── examples/
│   └── basic/
│       ├── MODULE.bazel
│       ├── BUILD.bazel
│       └── copy.bara.sky
├── tests/
│   ├── BUILD.bazel
│   └── testdata/
│       └── simple.bara.sky
├── .bazelrc
├── .bazelversion
├── .gitattributes
├── LICENSE                         # MIT
├── README.md
└── PLAN.md
```

## API Reference

### Rules

| Rule | Type | Description |
|------|------|-------------|
| `copybara_validate` | Build | Validates config, produces marker file |
| `copybara_run` | Executable | Generic copybara runner, args via `--` |
| `copybara_migrate` | Executable | Preset workflow runner |

### Macro

```starlark
copybara(
    name = "sync",
    config = "copy.bara.sky",
    workflow = "sync-docs",  # Optional
    deps = [],               # Additional config files
    force = False,           # --force flag
    ignore_noop = True,      # --ignore-noop flag
    dry_run = False,         # --dry-run flag
)
# Creates: sync.validate, sync.run, sync (if workflow specified)
```

### Provider

```starlark
CopybaraInfo(
    config = File,      # The .bara.sky file
    validated = bool,   # Whether validation passed
)
```

## Usage Examples

### Basic

```starlark
load("@rules_copybara//:copybara.bzl", "copybara")

copybara(
    name = "sync_docs",
    config = "copy.bara.sky",
    workflow = "sync-docs",
)
```

```bash
bazel build //:sync_docs.validate  # Validate config
bazel run //:sync_docs             # Run migration
bazel run //:sync_docs -- --force  # With extra args
```

### Generic Runner

```starlark
load("@rules_copybara//:copybara.bzl", "copybara_run")

copybara_run(
    name = "copybara",
    config = "copy.bara.sky",
)
```

```bash
bazel run //:copybara -- migrate copy.bara.sky sync-docs --force
bazel run //:copybara -- validate copy.bara.sky
bazel run //:copybara -- info copy.bara.sky
```

### Airgap Environment

```starlark
# MODULE.bazel
bazel_dep(name = "rules_copybara", version = "0.1.0")
bazel_dep(name = "copybara", version = "0.0.0-20250728-6672ce2")
archive_override(
    module_name = "copybara",
    urls = ["https://internal.mirror/copybara-20250728.tar.gz"],
    integrity = "sha256-...",
)
```

## Requirements

- Bazel 7.x or 8.x
- Java 21+ (Copybara requirement)

## License

MIT
