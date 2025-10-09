"""Execution rules for Bun commands."""

load("//bun/private:providers.bzl", "BunInstallInfo")

_BUN_TOOLCHAIN = "//bun:toolchain_type"
_DEFAULT_BUN_INSTALL = "$HOME/.local/share/bun"
_RUNFILES_LIB = "bazel_tools/tools/bash/runfiles/runfiles.bash"

_SCRIPT_TEMPLATE = """#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${RUNFILES_DIR:-}" && -z "${RUNFILES_MANIFEST_FILE:-}" ]]; then
  if [[ -f "$0.runfiles_manifest" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
  elif [[ -d "$0.runfiles" ]]; then
    export RUNFILES_DIR="$0.runfiles"
  fi
fi
if [[ -n "${RUNFILES_MANIFEST_FILE:-}" ]]; then
  while IFS= read -r line; do
    case "$line" in
      {_runfiles_lib}\\ *)
        source "${{line#* }}"
        break
        ;;
    esac
  done < "$RUNFILES_MANIFEST_FILE"
else
  source "${{RUNFILES_DIR}}/{_runfiles_lib}"
fi

bun_bin="$(rlocation "{bun_bin}")"
package_json="$(rlocation "{package_json}")"
node_modules_src="$(rlocation "{node_modules}")"
{lockfile_lookup}pkg_dir="$(dirname "$package_json")"

export BUN_INSTALL="${{BUN_INSTALL:-%s}}"

rm -rf "$pkg_dir/node_modules"
# TODO: consider switching to symlinks once we vet read-only runfiles support.
mkdir -p "$pkg_dir/node_modules"
cp -R "$node_modules_src"/. "$pkg_dir/node_modules"
{lockfile_sync}
cd "$pkg_dir"

has_script=0
{script_detection}
{missing_script_guard}
cmd=("$bun_bin")
if [[ {watch} -eq 1 ]]; then
  cmd+=("--watch")
fi
{command_dispatch}
{cmd_args_append}cmd+=("$@")
exec "${cmd[@]}"
""" % _DEFAULT_BUN_INSTALL


def _escape_shell(arg):
    return arg.replace("\\", "\\\\").replace('"', '\\"')


def _format_bun_args(args):
    if not args:
        return ""

    pieces = []
    for arg in args:
        pieces.append('"{}"'.format(_escape_shell(arg)))

    escaped = " ".join(pieces)
    return "cmd+=({})\n".format(escaped)


def _render_launcher(ctx, *, install_info, package_json, bun_bin_path, script, fallback, watch, bun_args, lockfile, require_script):
    cmd_args_append = _format_bun_args(bun_args)

    script_detection = ""
    missing_script_guard = ""
    command_dispatch = 'cmd+=("{fallback}")\n'.format(fallback = fallback)

    if script:
        script_detection = """if output=$("$bun_bin" --print "(() => { try { const pkg = require('./package.json'); const scripts = pkg.scripts || {}; return Object.prototype.hasOwnProperty.call(scripts, '%s') ? '1' : '0'; } catch (err) { return '0'; } })()") 2>/dev/null; then
  if [[ "$output" == '1' ]]; then
    has_script=1
  fi
fi
""" % script
        if require_script:
            missing_script_guard = """if [[ $has_script -ne 1 ]]; then
  echo "Expected package.json to define script '%s' for target %s" >&2
  exit 1
fi
""" % (script, ctx.label)
            command_dispatch = 'cmd+=("{script}")\n'.format(script = script)
        else:
            command_dispatch = """if [[ $has_script -eq 1 ]]; then
  cmd+=("{script}")
else
  cmd+=("{fallback}")
fi
""".format(script = script, fallback = fallback)

    script_detection = script_detection.replace("{", "{{").replace("}", "}}")
    missing_script_guard = missing_script_guard.replace("{", "{{").replace("}", "}}")
    command_dispatch = command_dispatch.replace("{", "{{").replace("}", "}}")

    lockfile_lookup = ""
    lockfile_sync = ""
    if lockfile:
        lockfile_lookup = 'lockfile="$(rlocation "{0}")"\n'.format(lockfile)
        lockfile_sync = 'cp "$lockfile" bun.lockb\n'

    script_content = _SCRIPT_TEMPLATE.format(
        _runfiles_lib = _RUNFILES_LIB,
        bun_bin = bun_bin_path,
        package_json = package_json.short_path,
        node_modules = install_info.node_modules.short_path,
        lockfile_lookup = lockfile_lookup,
        lockfile_sync = lockfile_sync.replace("{", "{{").replace("}", "}}"),
        script_detection = script_detection,
        missing_script_guard = missing_script_guard,
        command_dispatch = command_dispatch,
        cmd_args_append = cmd_args_append.replace("{", "{{").replace("}", "}}"),
        watch = 1 if watch else 0,
    )

    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(launcher, script_content, is_executable = True)
    return launcher


def _collect_runfiles(ctx, *, install_info, package_json, lockfile, toolchain):
    files = []
    if package_json:
        files.append(package_json)
    if lockfile:
        files.append(lockfile)

    data_files = []
    data_runfiles = []
    for dep in ctx.attr.data:
        if type(dep) == "File":
            data_files.append(dep)
        else:
            data_files.extend(dep.files.to_list())
            data_runfiles.append(dep[DefaultInfo].default_runfiles)

    runfiles = ctx.runfiles(files = files + data_files)
    runfiles = runfiles.merge(ctx.runfiles(transitive_files = depset([install_info.node_modules])))
    runfiles = runfiles.merge(ctx.runfiles(transitive_files = toolchain.default.files))
    runfiles = runfiles.merge(ctx.runfiles(files = [ctx.file._runfiles_lib]))
    for rf in data_runfiles:
        runfiles = runfiles.merge(rf)

    return runfiles


def _bun_command_impl(ctx, *, is_test):
    install_info = ctx.attr.install[BunInstallInfo]
    package_json = ctx.file.package_json or install_info.package_json
    lockfile = ctx.file.bun_lock or install_info.bun_lock
    toolchain = ctx.toolchains[_BUN_TOOLCHAIN]

    if not package_json:
        fail("A package_json file must be provided via the install target or explicitly.")

    script = ctx.attr.script
    fallback = ctx.attr.command
    if not script and not fallback:
        fail("Either `script` or `command` must be set for {}".format(ctx.label))
    if not fallback:
        fallback = script

    launcher = _render_launcher(
        ctx,
        install_info = install_info,
        package_json = package_json,
        bun_bin_path = toolchain.buninfo.target_tool_path,
        script = script,
        fallback = fallback,
        watch = ctx.attr.watch,
        bun_args = ctx.attr.bun_args,
        lockfile = lockfile.short_path if lockfile else None,
        require_script = ctx.attr.require_script,
    )

    runfiles = _collect_runfiles(
        ctx,
        install_info = install_info,
        package_json = package_json,
        lockfile = lockfile,
        toolchain = toolchain,
    )

    providers = [
        DefaultInfo(
            executable = launcher,
            runfiles = runfiles,
        ),
    ]
    if is_test:
        providers.append(coverage_common.CoverageInstrumentedInfo())

    return providers


def _make_bun_command_rule(is_test):
    attrs = {
        "install": attr.label(mandatory = True, providers = [BunInstallInfo]),
        "package_json": attr.label(allow_single_file = True),
        "bun_lock": attr.label(allow_single_file = True),
        "script": attr.string(),
        "command": attr.string(),
        "bun_args": attr.string_list(doc = "Additional arguments passed to Bun after the script/command."),
        "watch": attr.bool(default = False),
        "require_script": attr.bool(default = False, doc = "If true, fail when the requested script is missing."),
        "data": attr.label_list(allow_files = True),
        "_runfiles_lib": attr.label(
            default = Label("@bazel_tools//tools/bash/runfiles:runfiles"),
            allow_single_file = True,
        ),
    }
    return rule(
        implementation = lambda ctx: _bun_command_impl(ctx, is_test = is_test),
        attrs = attrs,
        executable = True,
        test = is_test,
        toolchains = [_BUN_TOOLCHAIN],
        doc = "Runs a Bun command, preferring package.json scripts when present.",
    )


bun_command_rule = _make_bun_command_rule(is_test = False)
bun_command_rule_test = _make_bun_command_rule(is_test = True)
