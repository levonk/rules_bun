"""Providers for Bun rules."""

BunInstallInfo = provider(
    doc = "Information produced by `bun_install` used by downstream Bun rules.",
    fields = {
        "node_modules": "Tree artifact containing the installed node_modules directory.",
        "package_json": "The package.json file used during installation.",
        "bun_lock": "The Bun lockfile used during installation, or None if not provided.",
        "install_manifest": "A manifest file produced by the install action for caching/debugging.",
    },
)
