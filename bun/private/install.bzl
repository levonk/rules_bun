"""Implementation of the `bun_install` rule."""

load("//bun/private:providers.bzl", "BunInstallInfo")

_BUN_TOOLCHAIN = "//bun:toolchain_type"

_DEFAULT_BUN_INSTALL = "$HOME/.local/share/bun"

def _bun_install_impl(ctx):
    toolchain = ctx.toolchains[_BUN_TOOLCHAIN]
    bun_bin = toolchain.buninfo.target_tool_path

    node_modules = ctx.actions.declare_directory("{}_node_modules".format(ctx.label.name))
    manifest = ctx.actions.declare_file("{}_install_manifest.json".format(ctx.label.name))

    inputs = [ctx.file.package_json]
    copy_lock = ""
    lock_name = ""
    if ctx.file.bun_lock:
        inputs.append(ctx.file.bun_lock)
        lock_name = ctx.file.bun_lock.basename
        copy_lock = "cp {bun_lock} \"$WORKDIR/{lock}\"".format(
            bun_lock = ctx.file.bun_lock.path,
            lock = ctx.file.bun_lock.basename,
        )

    data_files = []
    for item in ctx.attr.data:
        if hasattr(item, "files"):
            data_files.extend(item.files.to_list())
        else:
            data_files.append(item)
    inputs.extend(data_files)

    script_lines = [
        "set -euo pipefail",
        "export BUN_INSTALL=\"${BUN_INSTALL:-%s}\"" % _DEFAULT_BUN_INSTALL,
        "WORKDIR=\"$PWD/%s.work\"" % ctx.label.name,
        "rm -rf \"$WORKDIR\"",
        "mkdir -p \"$WORKDIR\"",
        "cp {pkg} \"$WORKDIR/package.json\"".format(pkg = ctx.file.package_json.path),
    ]
    if copy_lock:
        script_lines.append(copy_lock)
    install_cmd = [bun_bin, "install", "--no-progress"]
    if ctx.file.bun_lock:
        install_cmd.append("--frozen-lockfile")
    # TODO: consider switching to symlinks once we vet read-only runfiles support.
    script_lines.extend([
        "cd \"$WORKDIR\"",
        "{cmd}".format(cmd = " ".join(install_cmd)),
        "rm -rf \"{out}\"".format(out = node_modules.path),
        "mkdir -p \"{out}\"".format(out = node_modules.path),
        "cp -R node_modules/. \"{out}\"".format(out = node_modules.path),
        "cat <<'JSON' > \"{manifest}\"".format(manifest = manifest.path),
        "{",
        "  \"install\": \"%s\"," % ctx.label.name,
        "  \"package_json\": \"{pkg}\",".format(pkg = ctx.file.package_json.path),
        "  \"bun_lock\": \"{lock}\"".format(lock = ctx.file.bun_lock.path if ctx.file.bun_lock else ""),
        "}",
        "JSON",
    ])

    ctx.actions.run_shell(
        mnemonic = "BunInstall",
        progress_message = "Installing Bun dependencies for {}".format(ctx.label),
        command = "\n".join(script_lines),
        inputs = depset(inputs),
        tools = toolchain.default.files,
        outputs = [node_modules, manifest],
        use_default_shell_env = True,
    )

    runfiles = ctx.runfiles(files = data_files)
    providers = [
        DefaultInfo(
            files = depset([manifest]),
            data_runfiles = runfiles,
        ),
        BunInstallInfo(
            node_modules = node_modules,
            package_json = ctx.file.package_json,
            bun_lock = ctx.file.bun_lock,
            install_manifest = manifest,
        ),
    ]
    return providers

bun_install_rule = rule(
    implementation = _bun_install_impl,
    attrs = {
        "package_json": attr.label(
            doc = "Path to package.json to install dependencies from.",
            allow_single_file = True,
            mandatory = True,
        ),
        "bun_lock": attr.label(
            doc = "Optional bun.lockb lockfile for reproducible installs.",
            allow_single_file = True,
        ),
        "data": attr.label_list(
            doc = "Additional files to make available during install (for workspaces).",
            allow_files = True,
        ),
    },
    toolchains = [_BUN_TOOLCHAIN],
    doc = "Installs dependencies using Bun and exposes them via BunInstallInfo.",
)
