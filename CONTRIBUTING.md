# Contributing to rules_copybara

## Prerequisites

- Bazel 8.x or 9.x
- Java 21+ (required by Copybara)
- [Lefthook](https://github.com/evilmartians/lefthook) for git hooks
- [dprint](https://dprint.dev/) for formatting
- [buildifier](https://github.com/bazelbuild/buildtools) for Starlark formatting

## Setup

```bash
# Clone the repository
git clone https://github.com/albertocavalcante/rules_copybara.git
cd rules_copybara

# Install git hooks
lefthook install

# Verify everything works
bazel build //...
bazel test //...
```

## Development Workflow

### Building

```bash
bazel build //...
```

### Testing

```bash
# Run all tests
bazel test //...

# Run specific test
bazel test //tests:providers_test

# Run e2e tests
cd e2e/smoke && bazel build //...
```

### Formatting

```bash
# Format Starlark files
bazel run //:buildifier -- -mode=fix -r .

# Format markdown/json/yaml
dprint fmt

# Check formatting (CI mode)
buildifier -mode=check -lint=warn -r .
dprint check
```

### Updating Dependencies

When adding or updating dependencies in MODULE.bazel:

```bash
# Update the lockfile
bazel build //... --config=update

# Commit the updated lockfile
git add MODULE.bazel.lock
git commit -m "chore: update lockfile"
```

## Commit Messages

We use semantic commit messages. Format:

```
type(scope): description
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `chore`: Maintenance tasks
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `ci`: CI/CD changes
- `perf`: Performance improvements
- `build`: Build system changes

**Scopes (optional):**
- `validate`: copybara_validate rule
- `migrate`: copybara_migrate rule
- `run`: copybara_run rule
- `launcher`: Java launcher
- `e2e`: End-to-end tests

**Examples:**
```
feat(migrate): add dry-run support
fix(validate): handle missing config file
docs: update airgap instructions
chore: update dependencies
```

## Pull Request Checklist

- [ ] Tests pass (`bazel test //...`)
- [ ] Formatting is correct (`buildifier`, `dprint`)
- [ ] Commit messages follow semantic format
- [ ] Documentation updated if needed
- [ ] Lockfile updated if deps changed
- [ ] e2e tests updated for new features

## Releasing

Releases are automated via GitHub Actions:

1. Push a semantic version tag: `git tag v0.1.0 && git push --tags`
2. CI creates GitHub release
3. Publishes to Bazel Central Registry

## Architecture

```
rules_copybara/
├── copybara.bzl          # Public API
├── private/
│   ├── providers.bzl     # CopybaraInfo provider
│   ├── copybara_*.bzl    # Rule implementations
│   └── launcher/         # Cross-platform Java launcher
├── tests/                # Unit tests
└── e2e/smoke/            # Integration tests
```

### Key Design Decisions

1. **No shell scripts**: Cross-platform via Java launcher
2. **Bzlmod only**: Modern Bazel, no legacy support
3. **Bazel 8.x/9.x**: Tested against latest stable versions
4. **Airgap-friendly**: Override copybara via MODULE.bazel overrides
5. **Lockfile committed**: Reproducible builds across environments
