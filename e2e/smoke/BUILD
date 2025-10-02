"""End-to-end smoke tests validating the rules_bun surface."""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@levonk_rules_bun//bun:defs.bzl", "bun_build", "bun_install", "bun_test", "js_auto_install")
load(":fake_handlers.bzl", "all_handlers")

filegroup(
    name = "sample_pkg",
    srcs = [
        "package.json",
        "bun.lockb",
        "pnpm-lock.yaml",
        "yarn.lock",
        "package-lock.json",
    ],
)

bun_install(
    name = "bun_deps",
    package_json = "package.json",
    bun_lock = "bun.lockb",
    data = [":sample_pkg"],
)

bun_build(
    name = "bun_build",
    install = ":bun_deps",
    script = "build",
)

bun_test(
    name = "bun_tests",
    install = ":bun_deps",
    script = "test",
)

js_auto_install(
    name = "auto_bun",
    package_json = "package.json",
    bun_lock = "bun.lockb",
    handlers = all_handlers(),
)

js_auto_install(
    name = "auto_pnpm",
    package_json = "package.json",
    pnpm_lock = "pnpm-lock.yaml",
    handlers = all_handlers(),
)

js_auto_install(
    name = "auto_yarn",
    package_json = "package.json",
    yarn_lock = "yarn.lock",
    handlers = all_handlers(),
)

js_auto_install(
    name = "auto_npm",
    package_json = "package.json",
    npm_lock = "package-lock.json",
    handlers = all_handlers(),
)

build_test(
    name = "smoke_test",
    targets = [
        ":bun_build",
        ":bun_tests",
        ":auto_bun",
        ":auto_pnpm",
        ":auto_yarn",
        ":auto_npm",
    ],
)
