"""Stub handlers to verify package-manager detection in e2e tests."""


def _flatten(values):
    result = []
    if type(values) not in ("list", "tuple"):
        return result

    for value in values:
        if value == None:
            continue
        kind = type(value)
        if kind in ("list", "tuple"):
            for nested in value:
                if nested != None:
                    result.append(nested)
        else:
            result.append(value)

    return result


def _emit_marker(name, package_json, manager, extra_inputs):
    marker_rule = name + "_marker"
    marker_file = name + ".manager"
    native.genrule(
        name = marker_rule,
        outs = [marker_file],
        cmd = "echo {mgr} > $@".format(mgr = manager),
        cmd_bat = "echo {mgr} > $@".format(mgr = manager),
        visibility = ["//visibility:public"],
        stamp = 0,
    )

    srcs = [package_json, ":" + marker_rule]
    for value in _flatten(extra_inputs):
        kind = type(value)
        if kind in ("Label", "string"):
            srcs.append(value)

    native.filegroup(
        name = name,
        srcs = srcs,
        visibility = ["//visibility:public"],
    )


def bun_handler(name, package_json, **kwargs):
    _emit_marker(name, package_json, "bun", kwargs.values())


def pnpm_handler(name, package_json, **kwargs):
    _emit_marker(name, package_json, "pnpm", kwargs.values())


def yarn_handler(name, package_json, **kwargs):
    _emit_marker(name, package_json, "yarn", kwargs.values())


def npm_handler(name, package_json, **kwargs):
    _emit_marker(name, package_json, "npm", kwargs.values())


def all_handlers():
    return {
        "bun": bun_handler,
        "pnpm": pnpm_handler,
        "yarn": yarn_handler,
        "npm": npm_handler,
    }
