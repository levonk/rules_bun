# Bazel rules for bun

## Installation

Use the snippet from <https://github.com/levonk/rules_bun/releases> for your preferred release. The examples below show both `WORKSPACE.bazel` and `MODULE.bazel` setups.

```starlark
# WORKSPACE.bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "levonk_rules_bun",
    url = "https://github.com/levonk/rules_bun/releases/download/v0.1.0/rules_bun-v0.1.0.tar.gz",
    sha256 = "<sha256>",
    strip_prefix = "rules_bun-0.1.0",
)

load("@levonk_rules_bun//bun:repositories.bzl", "rules_bun_dependencies", "bun_register_toolchains")

rules_bun_dependencies()
bun_register_toolchains(name = "bun")
```

```starlark
# MODULE.bazel
bun = use_extension("//bun:extensions.bzl", "bun")
bun.toolchain(bun_version = "1.1.23")
use_repo(bun, "bun_toolchains")

register_toolchains("@bun_toolchains//:all")
```

### Toolchains

- Bun downloads automatically when missing. If `BUN_INSTALL` is already set it is respected; otherwise Bun installs into `$HOME/.local/share/bun`.
- Prebuilt archives are fetched for macOS (x64/arm64), Linux (x64), and Windows (x64).

## Rules

- **`bun_install`**: Runs `bun install`, producing a hermetic `node_modules` tree and exposing `BunInstallInfo`.
- **`bun_run`**: Executes a `package.json` script via `bun <script>`; when the script is absent it falls back to the Bun CLI subcommand.
- **`bun_build`**: Convenience wrapper around `bun_run` defaulting to the `build` script.
- **`bun_watch`**: Launches `bun --watch <script>` for development workflows.
- **`bun_test`**: Wraps Bun tests in a Bazel `test` target, enabling caching and coverage instrumentation.
- **`js_auto_install`**: Detects lockfiles and dispatches to Bun, pnpm, Yarn, or npm. Provide handlers for non-Bun managers you want to support.

## Usage
```starlark
load("@levonk_rules_bun//bun:defs.bzl", "bun_build", "bun_install", "bun_test")

bun_install(
    name = "web_deps",
    package_json = "package.json",
    bun_lock = "bun.lockb",
)

bun_build(
    name = "web_build",
    install = ":web_deps",
    script = "build",
    args = ["--target", "bun"],
)

bun_test(
    name = "web_test",
    install = ":web_deps",
    script = "test",
)
```

## Auto-detecting the package manager
```starlark
load("@levonk_rules_bun//bun:defs.bzl", "js_auto_install")
load("@aspect_rules_js//npm:defs.bzl", "npm_install")

js_auto_install(
    name = "deps",
    package_json = "package.json",
    bun_lock = "bun.lockb",
    pnpm_lock = "pnpm-lock.yaml",
    yarn_lock = "yarn.lock",
    npm_lock = "package-lock.json",
    handlers = {
        "npm": npm_install,
    },
)
```

packageManager field: When package.json specifies \"packageManager\": \"bun@1.x\", Bun wins even if other lockfiles exist.
Conflict detection: If incompatible lockfiles (for example bun.lockb and pnpm-lock.yaml) are present, js_auto_install fails fast so the repo can be tidied.
Testing
Unit tests:
//bun/tests:detect_test exercises the lockfile detector.
//bun/tests:versions_test validates Bun release metadata.
End-to-end smoke test: //e2e/smoke:smoke_test verifies install instructions from an external workspace.
Run locally:

```bash
bazel test //bun/tests/...
bazel test //e2e/smoke:smoke_test
```

# Bazel rules for bun

## Installation

Use the snippet from <https://github.com/levonk/rules_bun/releases> for your preferred release. The examples below show both [WORKSPACE.bazel](cci:7://file:///home/micro/p/gh/levonk/rules_bun/e2e/smoke/WORKSPACE.bazel:0:0-0:0) and [MODULE.bazel](cci:7://file:///home/micro/p/gh/levonk/rules_bun/MODULE.bazel:0:0-0:0) setups.

```starlark
# WORKSPACE.bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "levonk_rules_bun",
    url = "[https://github.com/levonk/rules_bun/releases/download/v0.1.0/rules_bun-v0.1.0.tar.gz](https://github.com/levonk/rules_bun/releases/download/v0.1.0/rules_bun-v0.1.0.tar.gz)",
    sha256 = "<sha256>",
    strip_prefix = "rules_bun-0.1.0",
)

load("@levonk_rules_bun//bun:repositories.bzl", "rules_bun_dependencies", "bun_register_toolchains")

rules_bun_dependencies()
bun_register_toolchains(name = "bun")
```

```starlark
# MODULE.bazel
bun = use_extension("//bun:extensions.bzl", "bun")
bun.toolchain(bun_version = "1.1.23")
use_repo(bun, "bun_toolchains")

register_toolchains("@bun_toolchains//:all")
```

- Toolchain install directory: Bun downloads automatically when missing. If BUN_INSTALL is already set it is respected; otherwise Bun installs into $HOME/.local/share/bun.
- Platform coverage: macOS (x64/arm64), Linux (x64), and Windows (x64) archives are fetched from upstream releases.

## Rules
- `bun_install`: Runs bun install, producing a hermetic node_modules tree and exposing BunInstallInfo.
- `bun_run`: Executes a package.json script via bun <script>; when the script is absent it falls back to the Bun CLI subcommand.
- `bun_build`: Convenience wrapper around bun_run defaulting to the build script.
- `bun_watch`: Launches bun --watch <script> for development workflows.
- `bun_test`: Wraps Bun tests in a Bazel test target, enabling caching and coverage instrumentation.
- `js_auto_install`: Detects lockfiles and dispatches to Bun, pnpm, Yarn, or npm. Provide handlers for non-Bun managers you want to support.

## Usage
```starlark
load("@levonk_rules_bun//bun:defs.bzl", "bun_build", "bun_install", "bun_test")

bun_install(
    name = "web_deps",
    package_json = "package.json",
    bun_lock = "bun.lockb",
)

bun_build(
    name = "web_build",
    install = ":web_deps",
    script = "build",
    args = ["--target", "bun"],
)

bun_test(
    name = "web_test",
    install = ":web_deps",
    script = "test",
)
```

### Auto-detecting the package manager
```starlark
load("@levonk_rules_bun//bun:defs.bzl", "js_auto_install")
load("@aspect_rules_js//npm:defs.bzl", "npm_install")

js_auto_install(
    name = "deps",
    package_json = "package.json",
    bun_lock = "bun.lockb",
    pnpm_lock = "pnpm-lock.yaml",
    yarn_lock = "yarn.lock",
    npm_lock = "package-lock.json",
    handlers = {
        "npm": npm_install,
    },
)
```

- `packageManager` field: When `package.json` specifies `\"packageManager\": \"bun@1.x\"`, Bun wins even if other lockfiles exist.
- Conflict detection: If incompatible lockfiles (for example `bun.lockb` and `pnpm-lock.yaml`) are present, `js_auto_install` fails fast so the repo can be tidied.

### Testing
- Unit tests:
  - `//bun/tests:detect_test` exercises the lockfile detector.
  - `//bun/tests:versions_test` validates Bun release metadata.
- End-to-end smoke test: `//e2e/smoke:smoke_test` verifies install instructions from an external workspace.

### Run locally:
```bash
bazel test //bun/tests/...
bazel test //e2e/smoke:smoke_test
```

## Contributing
- Formatting: Execute `bazel run //:lint` (buildifier/buildozer) before sending a PR.
- Releases: Tag a version; GitHub Actions packages the archive automatically.
- Feedback: File issues or feature requests at <https://github.com/levonk/rules_bun/issues>.
