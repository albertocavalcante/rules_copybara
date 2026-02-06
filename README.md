# rules_copybara

Bazel macros for running [Copybara](https://github.com/google/copybara) workflows.

## Design

Inspired by [google/copybara#147](https://github.com/google/copybara/issues/147), specifically
[@michaelschiff's approach](https://github.com/google/copybara/issues/147#issuecomment-1326932855)
using `java_binary` with preset `args`.

**Key insight**: Use native `java_binary` with `runtime_deps` pointing to copybara's library target,
then set `args` at build time. No wrapper scripts needed - works cross-platform natively.

## Requirements

- Bazel 8.x or 9.x
- Java 21+

## Quick Start

Add to your `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_copybara", version = "0.1.0")
```

Create a `BUILD.bazel`:

```starlark
load("@rules_copybara//:copybara.bzl", "copybara")

copybara(
    name = "sync_docs",
    config = "copy.bara.sky",
    workflow = "sync-docs",
)
```

Run:

```bash
bazel run //:sync_docs
```

## Macros

### `copybara_migrate`

Creates a runnable migrate target.

```starlark
load("@rules_copybara//:copybara.bzl", "copybara_migrate")

copybara_migrate(
    name = "sync_docs",
    config = "copy.bara.sky",
    workflow = "sync-docs",
    force = True,       # Optional: --force flag
    ignore_noop = True, # Optional: --ignore-noop (default)
)
```

### `copybara_migrate_with_mode`

Migrate target with configurable mode via build flag.

```starlark
load("@rules_copybara//:copybara.bzl", "copybara_migrate_with_mode")

copybara_migrate_with_mode(
    name = "sync_docs",
    config = "copy.bara.sky",
    workflow = "sync-docs",
    default_mode = "dry-run",  # or "migrate"
)
```

```bash
# Migrate mode
bazel run //:sync_docs --//:sync_docs.mode=migrate

# Dry-run mode
bazel run //:sync_docs --//:sync_docs.mode=dry-run
```

### `copybara_validate`

Validates a configuration file.

```starlark
load("@rules_copybara//:copybara.bzl", "copybara_validate")

copybara_validate(
    name = "validate",
    config = "copy.bara.sky",
    tags = ["manual"],
)
```

### `copybara` (Convenience)

Creates both validate and migrate targets.

```starlark
load("@rules_copybara//:copybara.bzl", "copybara")

copybara(
    name = "sync",
    config = "copy.bara.sky",
    workflow = "sync-docs",
)
# Creates: //:sync.validate, //:sync
```

## Airgap / Custom Copybara

Override copybara source in `MODULE.bazel`:

```starlark
bazel_dep(name = "copybara", version = "0.0.0-20250728-6672ce2")

# Internal mirror
archive_override(
    module_name = "copybara",
    urls = ["https://internal/copybara.tar.gz"],
    integrity = "sha256-...",
)
```

## License

MIT
