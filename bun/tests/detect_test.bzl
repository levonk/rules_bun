"""Tests for the package-manager detection helpers."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//bun/private:detect.bzl", "analyze_lockfiles", "choose_package_manager")


def _default_to_bun_impl(ctx):
    env = unittest.begin(ctx)
    decision = choose_package_manager({}, package_manager_field = None)
    asserts.equals(env, "bun", decision.manager)
    asserts.equals(env, "default", decision.reason)
    return unittest.end(env)


def _detect_bun_lock_impl(ctx):
    env = unittest.begin(ctx)
    lockfile_map = {"bun.lockb": "//:bun.lockb"}
    matches = analyze_lockfiles(lockfile_map)
    asserts.equals(env, 1, len(matches))
    asserts.equals(env, "bun", matches[0].manager)
    decision = choose_package_manager(lockfile_map, package_manager_field = None)
    asserts.equals(env, "bun", decision.manager)
    asserts.equals(env, "lockfile", decision.reason)
    asserts.equals(env, "//:bun.lockb", decision.lockfile)
    return unittest.end(env)


def _package_manager_override_impl(ctx):
    env = unittest.begin(ctx)
    lockfile_map = {"pnpm-lock.yaml": "//:pnpm-lock.yaml"}
    decision = choose_package_manager(lockfile_map, package_manager_field = "bun@1.1.23")
    asserts.equals(env, "bun", decision.manager)
    asserts.equals(env, "package_manager", decision.reason)
    return unittest.end(env)


def _conflict_detection_impl(ctx):
    env = unittest.begin(ctx)
    lockfile_map = {
        "bun.lockb": "//:bun.lockb",
        "pnpm-lock.yaml": "//:pnpm-lock.yaml",
    }
    decision = choose_package_manager(lockfile_map, package_manager_field = None)
    asserts.equals(env, "conflict", decision.reason)
    asserts.equals(env, None, decision.manager)
    asserts.true(env, len(decision.matches) == 2)
    return unittest.end(env)


_default_to_bun_test = unittest.make(_default_to_bun_impl)
_detect_bun_lock_test = unittest.make(_detect_bun_lock_impl)
_package_manager_override_test = unittest.make(_package_manager_override_impl)
_conflict_detection_test = unittest.make(_conflict_detection_impl)


def detect_test_suite(name):
    unittest.suite(
        name,
        _default_to_bun_test,
        _detect_bun_lock_test,
        _package_manager_override_test,
        _conflict_detection_test,
    )
