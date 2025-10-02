"""Unit tests for starlark helpers
See https://bazel.build/rules/testing#testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//bun/private:versions.bzl", "TOOL_VERSIONS")

def _versions_schema_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.true(env, len(TOOL_VERSIONS.keys()) > 0, "Expected at least one Bun version")
    for version, platforms in TOOL_VERSIONS.items():
        asserts.true(env, len(platforms.keys()) > 0, "{0} should define platform metadata".format(version))
        for platform, meta in platforms.items():
            for field in ["url", "strip_prefix"]:
                asserts.true(
                    env,
                    hasattr(meta, field),
                    "{0}/{1} missing field '{2}'".format(version, platform, field),
                )
            asserts.true(
                env,
                hasattr(meta, "sha256") and len(meta.sha256) > 0,
                "{0}/{1} missing sha256".format(version, platform),
            )
    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
_schema_test = unittest.make(_versions_schema_test_impl)

def versions_test_suite(name):
    unittest.suite(name, _schema_test)
