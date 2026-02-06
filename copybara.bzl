"""Public API for rules_copybara.

Cross-platform Bazel macros for running Copybara workflows.

## Design

Inspired by https://github.com/google/copybara/issues/147
Specifically, @michaelschiff's approach using java_binary with preset args:
https://github.com/google/copybara/issues/147#issuecomment-1326932855

Key insight: Use native `java_binary` with `runtime_deps` pointing to copybara's
library target, then set `args` at build time. This avoids wrapper scripts and
works cross-platform natively.

Supports `select()` for different modes (dry-run vs migrate) via `string_flag`.

## Example Usage

```starlark
load("@rules_copybara//:copybara.bzl", "copybara_migrate")

copybara_migrate(
    name = "sync_docs",
    config = "copy.bara.sky",
    workflow = "sync-docs",
)

# Run: bazel run //:sync_docs
```

For mode switching:
```starlark
load("@rules_copybara//:copybara.bzl", "copybara_migrate_with_mode")

copybara_migrate_with_mode(
    name = "sync_docs",
    config = "copy.bara.sky",
    workflow = "sync-docs",
)

# Migrate: bazel run //:sync_docs
# Dry-run: bazel run //:sync_docs --//:sync_docs.mode=dry-run
```
"""

load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
load("@rules_java//java:defs.bzl", "java_binary")

# Copybara library target from BCR
# See: https://github.com/google/copybara/blob/master/java/com/google/copybara/BUILD
_COPYBARA_MAIN = "@copybara//java/com/google/copybara:copybara_main"

def copybara_migrate(
        name,
        config,
        workflow,
        force = False,
        ignore_noop = True,
        visibility = None,
        tags = [],
        **kwargs):
    """Creates a runnable Copybara migrate target.

    Uses native java_binary with preset args - cross-platform, no wrapper scripts.

    Inspired by: https://github.com/google/copybara/issues/147#issuecomment-1326932855

    Args:
        name: Target name.
        config: The copy.bara.sky configuration file.
        workflow: The workflow name to run.
        force: If True, adds --force flag.
        ignore_noop: If True (default), adds --ignore-noop flag.
        visibility: Target visibility.
        tags: Target tags.
        **kwargs: Additional args passed to java_binary.

    Example:
        copybara_migrate(
            name = "sync_docs",
            config = "copy.bara.sky",
            workflow = "sync-docs",
        )

        # Run: bazel run //:sync_docs
    """
    args = ["migrate", "$(location %s)" % config, workflow]
    if force:
        args.append("--force")
    if ignore_noop:
        args.append("--ignore-noop")

    java_binary(
        name = name,
        main_class = "com.google.copybara.Main",
        runtime_deps = [_COPYBARA_MAIN],
        args = args,
        data = [config],
        visibility = visibility,
        tags = tags,
        **kwargs
    )

def copybara_migrate_with_mode(
        name,
        config,
        workflow,
        default_mode = "migrate",
        visibility = None,
        tags = [],
        **kwargs):
    """Creates a Copybara migrate target with configurable mode via build flag.

    Supports switching between dry-run and migrate modes at build time using
    Bazel's select() mechanism with string_flag.

    Inspired by: https://github.com/google/copybara/issues/147#issuecomment-1326932855

    Args:
        name: Target name.
        config: The copy.bara.sky configuration file.
        workflow: The workflow name to run.
        default_mode: Default mode ("migrate" or "dry-run").
        visibility: Target visibility.
        tags: Target tags.
        **kwargs: Additional args passed to java_binary.

    Example:
        copybara_migrate_with_mode(
            name = "sync_docs",
            config = "copy.bara.sky",
            workflow = "sync-docs",
        )

        # Migrate: bazel run //:sync_docs
        # Dry-run: bazel run //:sync_docs --//:sync_docs.mode=dry-run
    """
    string_flag(
        name = name + ".mode",
        build_setting_default = default_mode,
        visibility = visibility,
    )

    native.config_setting(
        name = name + ".mode_migrate",
        flag_values = {":%s.mode" % name: "migrate"},
    )

    native.config_setting(
        name = name + ".mode_dry_run",
        flag_values = {":%s.mode" % name: "dry-run"},
    )

    java_binary(
        name = name,
        main_class = "com.google.copybara.Main",
        runtime_deps = [_COPYBARA_MAIN],
        args = select({
            ":%s.mode_migrate" % name: [
                "migrate",
                "$(location %s)" % config,
                workflow,
                "--ignore-noop",
            ],
            ":%s.mode_dry_run" % name: [
                "migrate",
                "--dry-run",
                "$(location %s)" % config,
                workflow,
            ],
        }),
        data = [config],
        visibility = visibility,
        tags = tags,
        **kwargs
    )

def copybara_validate(
        name,
        config,
        visibility = None,
        tags = [],
        **kwargs):
    """Creates a Copybara validate target.

    Validates the configuration file. Runs as java_binary for cross-platform support.

    Args:
        name: Target name.
        config: The copy.bara.sky configuration file.
        visibility: Target visibility.
        tags: Target tags (add "requires-network", "no-sandbox" if git resolution needed).
        **kwargs: Additional args passed to java_binary.

    Example:
        copybara_validate(
            name = "validate",
            config = "copy.bara.sky",
            tags = ["manual"],
        )

        # Run: bazel run //:validate
    """
    java_binary(
        name = name,
        main_class = "com.google.copybara.Main",
        runtime_deps = [_COPYBARA_MAIN],
        args = ["validate", "$(location %s)" % config],
        data = [config],
        visibility = visibility,
        tags = tags,
        **kwargs
    )

def copybara(
        name,
        config,
        workflow = None,
        visibility = None,
        tags = [],
        **kwargs):
    """Convenience macro that creates validate and optionally migrate targets.

    Args:
        name: Base name for targets.
        config: The copy.bara.sky configuration file.
        workflow: Optional workflow name. If provided, creates migrate target.
        visibility: Target visibility.
        tags: Target tags.
        **kwargs: Additional args (force, ignore_noop for migrate).

    Example:
        copybara(
            name = "sync",
            config = "copy.bara.sky",
            workflow = "sync-docs",
        )
        # Creates: //:sync.validate, //:sync
    """
    copybara_validate(
        name = name + ".validate",
        config = config,
        visibility = visibility,
        tags = tags + ["manual"],
    )

    if workflow:
        copybara_migrate(
            name = name,
            config = config,
            workflow = workflow,
            visibility = visibility,
            tags = tags,
            **kwargs
        )
