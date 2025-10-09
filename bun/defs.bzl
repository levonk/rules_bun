"""Public API for Bun Bazel rules."""

load("//bun/private:command.bzl", "bun_command_rule", "bun_command_rule_test")
load("//bun/private:detect.bzl", "choose_package_manager")
load("//bun/private:install.bzl", "bun_install_rule")


def bun_install(*, name, package_json, bun_lock = None, data = None, visibility = None, **kwargs):
    """Installs JavaScript dependencies using Bun."""
    params = {
        "name": name,
        "package_json": package_json,
        "bun_lock": bun_lock,
        "data": data or [],
    }
    if visibility != None:
        params["visibility"] = visibility
    params.update(kwargs)
    if params["bun_lock"] == None:
        params.pop("bun_lock")
    bun_install_rule(**params)


def _invoke_bun_command(*, rule, name, install, script = None, default_command = None, args = None, watch = False, package_json = None, bun_lock = None, data = None, visibility = None, **kwargs):
    params = {
        "name": name,
        "install": install,
        "script": script,
        "command": default_command,
        "args": args or [],
        "watch": watch,
        "data": data or [],
    }
    if package_json != None:
        params["package_json"] = package_json
    if bun_lock != None:
        params["bun_lock"] = bun_lock
    if visibility != None:
        params["visibility"] = visibility
    params.update(kwargs)
    rule(**params)


def bun_run(*, name, install, script, args = None, package_json = None, bun_lock = None, data = None, visibility = None, **kwargs):
    """Runs `bun <script>` after ensuring dependencies are installed."""
    if not script:
        fail("bun_run requires a `script` argument (for example, script = \"dev\").")
    _invoke_bun_command(
        rule = bun_command_rule,
        name = name,
        install = install,
        script = script,
        default_command = script,
        args = args,
        package_json = package_json,
        bun_lock = bun_lock,
        data = data,
        visibility = visibility,
        **kwargs
    )


def bun_build(*, name, install, script = None, args = None, package_json = None, bun_lock = None, data = None, visibility = None, **kwargs):
    """Runs Bun build, defaulting to the `build` script."""
    actual_script = script or "build"
    _invoke_bun_command(
        rule = bun_command_rule,
        name = name,
        install = install,
        script = actual_script,
        default_command = actual_script,
        args = args,
        package_json = package_json,
        bun_lock = bun_lock,
        data = data,
        visibility = visibility,
        **kwargs
    )


def bun_watch(*, name, install, script, args = None, package_json = None, bun_lock = None, data = None, visibility = None, **kwargs):
    """Runs `bun --watch <script>` for development workflows."""
    if not script:
        fail("bun_watch requires a `script` argument (for example, script = \"dev\").")
    _invoke_bun_command(
        rule = bun_command_rule,
        name = name,
        install = install,
        script = script,
        default_command = script,
        args = args,
        watch = True,
        package_json = package_json,
        bun_lock = bun_lock,
        data = data,
        visibility = visibility,
        **kwargs
    )


def bun_test(*, name, install, script = None, args = None, package_json = None, bun_lock = None, data = None, visibility = None, **kwargs):
    """Runs Bun tests as a Bazel test target."""
    actual_script = script or "test"
    _invoke_bun_command(
        rule = bun_command_rule_test,
        name = name,
        install = install,
        script = actual_script,
        default_command = actual_script,
        args = args,
        package_json = package_json,
        bun_lock = bun_lock,
        data = data,
        visibility = visibility,
        **kwargs
    )


def js_auto_install(*, name, package_json, bun_lock = None, pnpm_lock = None, yarn_lock = None, npm_lock = None, npm_shrinkwrap = None, package_manager = None, handlers = None, data = None, visibility = None, **kwargs):
    """Chooses an install strategy based on detected lockfiles."""
    lockfile_map = {}
    if bun_lock != None:
        lockfile_map["bun.lockb"] = bun_lock
    if pnpm_lock != None:
        lockfile_map["pnpm-lock.yaml"] = pnpm_lock
    if yarn_lock != None:
        lockfile_map["yarn.lock"] = yarn_lock
    if npm_lock != None:
        lockfile_map["package-lock.json"] = npm_lock
    if npm_shrinkwrap != None:
        lockfile_map["npm-shrinkwrap.json"] = npm_shrinkwrap

    decision = choose_package_manager(lockfile_map, package_manager_field = package_manager)

    if decision.reason == "conflict":
        names = [match.key for match in decision.matches]
        fail("Conflicting lockfiles {} detected for target {}".format(names, name))

    manager = decision.manager or "bun"
    if manager == "bun":
        bun_install(
            name = name,
            package_json = package_json,
            bun_lock = bun_lock,
            data = data,
            visibility = visibility,
            **kwargs
        )
        return

    handler_map = handlers or {}
    handler = handler_map.get(manager)
    if handler == None:
        fail("Detected package manager '{}' but no handler was provided via handlers={{...}}.".format(manager))

    params = {
        "name": name,
        "package_json": package_json,
        "data": data or [],
    }
    if visibility != None:
        params["visibility"] = visibility
    params.update(kwargs)

    if manager == "pnpm" and pnpm_lock != None:
        params.setdefault("pnpm_lock", pnpm_lock)
    elif manager == "yarn" and yarn_lock != None:
        params.setdefault("yarn_lock", yarn_lock)
    elif manager == "npm":
        if npm_lock != None:
            params.setdefault("package_lock", npm_lock)
        if npm_shrinkwrap != None:
            params.setdefault("npm_shrinkwrap", npm_shrinkwrap)

    handler(**params)
