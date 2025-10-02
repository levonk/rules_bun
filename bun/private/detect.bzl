"""Helpers to detect the JavaScript package manager from lockfiles."""

# Order matters: first match wins when no conflicts exist.
_DETECTION_ORDER = [
    ("bun", "bun.lockb"),
    ("pnpm", "pnpm-lock.yaml"),
    ("yarn", "yarn.lock"),
    ("npm", "package-lock.json"),
    ("npm", "npm-shrinkwrap.json"),
]

_PACKAGE_MANAGER_ALIASES = {
    "npm": "npm",
    "pnpm": "pnpm",
    "yarn": "yarn",
    "bun": "bun",
}


def _normalize_package_manager(value):
    if not value:
        return None
    manager = value.split("@", 1)[0]
    return _PACKAGE_MANAGER_ALIASES.get(manager)


def analyze_lockfiles(lockfile_map):
    """Returns ordered matches discovered in the given lockfile map.

    Args:
        lockfile_map: dict mapping lockfile basenames to workspace-relative paths.

    Returns:
        A list of structs with fields `(manager, key, path)` sorted by detection order.
    """
    matches = []
    for manager, key in _DETECTION_ORDER:
        if key in lockfile_map:
            matches.append(struct(manager = manager, key = key, path = lockfile_map[key]))
    return matches


def choose_package_manager(lockfile_map, package_manager_field = None):
    """Chooses a package manager based on lockfiles and optional packageManager field.

    Args:
        lockfile_map: dict mapping lockfile basenames to workspace-relative paths.
        package_manager_field: optional string from package.json `packageManager`.

    Returns:
        Struct with fields:
            manager: selected manager name (`bun`, `pnpm`, `yarn`, `npm`) or None
            lockfile: path to the discovered lockfile or None
            key: basename of the lockfile that triggered the selection or None
            matches: list of all detected matches (see `analyze_lockfiles`).
            reason: either "package_manager", "lockfile", or "default".
    """
    matches = analyze_lockfiles(lockfile_map)
    normalized = _normalize_package_manager(package_manager_field)

    if normalized:
        # Honor the explicit packageManager field when present.
        for match in matches:
            if match.manager == normalized:
                return struct(
                    manager = normalized,
                    lockfile = match.path,
                    key = match.key,
                    matches = matches,
                    reason = "package_manager",
                )
        return struct(
            manager = normalized,
            lockfile = None,
            key = None,
            matches = matches,
            reason = "package_manager",
        )

    if not matches:
        return struct(
            manager = "bun",
            lockfile = lockfile_map.get("bun.lockb"),
            key = "bun.lockb" if "bun.lockb" in lockfile_map else None,
            matches = matches,
            reason = "default",
        )

    first = matches[0]
    # Detect conflicting lockfiles pointing at different managers.
    for match in matches[1:]:
        if match.manager != first.manager:
            return struct(
                manager = None,
                lockfile = None,
                key = None,
                matches = matches,
                reason = "conflict",
            )

    return struct(
        manager = first.manager,
        lockfile = first.path,
        key = first.key,
        matches = matches,
        reason = "lockfile",
    )
