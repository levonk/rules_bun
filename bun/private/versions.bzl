"""Mirror of Bun release metadata used by toolchains.

Each entry provides the download URL, optional SHA-256 checksum, and
strip_prefix needed to unpack the archive for a given platform. The values are
sourced from https://github.com/oven-sh/bun/releases and should be kept
reasonably up to date. The integrity field is optional; when omitted Bazel will
skip verification which is handy while iterating locally. For releases you
should fill in the SHA-256 for reproducibility.
"""

# Integrity hashes can be computed with
#   shasum -a 256 <file>
# or
#   openssl dgst -sha256 <file>
TOOL_VERSIONS = {
    # 1.1.23 released 2024-07-29
    "1.1.23": {
        "x86_64-apple-darwin": struct(
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.23/bun-darwin-x64.zip",
            strip_prefix = "bun-darwin-x64",
            sha256 = "9383d1c1d4ba92d20af77e5372d3672c6a7f7b2dd248097bd97d3ae59a0ad90d",
        ),
        "aarch64-apple-darwin": struct(
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.23/bun-darwin-aarch64.zip",
            strip_prefix = "bun-darwin-aarch64",
            sha256 = "d0675b82551a45eee8541525614a8b0f392876daa68be88a2ad2e6fdd8b32c96",
        ),
        "x86_64-pc-windows-msvc": struct(
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.23/bun-windows-x64.zip",
            strip_prefix = "bun-windows-x64",
            sha256 = "f6f327cfa732ecc001c96b4f3c985edf69355203819cf5b47eea90b9d51faba8",
        ),
        "x86_64-unknown-linux-gnu": struct(
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.23/bun-linux-x64.zip",
            strip_prefix = "bun-linux-x64",
            sha256 = "e32342cc5ec76b9bf1ac2b9b7d0665d72093ccb3b8a05f7b14473d952d227edd",
        ),
    },
    # 1.1.8 retained for compatibility.
    "1.1.8": {
        "x86_64-apple-darwin": struct(
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.8/bun-darwin-x64.zip",
            strip_prefix = "bun-darwin-x64",
            sha256 = "8e1b174be7f5083cabd6eb1a51dabf9022a756977d6d38f7c7c28c69014e4eb5",
        ),
        "aarch64-apple-darwin": struct(
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.8/bun-darwin-aarch64.zip",
            strip_prefix = "bun-darwin-aarch64",
            sha256 = "0d6b56a06bd9158aabca49b0096cb70f1216adb244eeced2c2f88ef099462611",
        ),
        "x86_64-pc-windows-msvc": struct(
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.8/bun-windows-x64.zip",
            strip_prefix = "bun-windows-x64",
            sha256 = "6c60594348d2657e58fb97b07f22a02d69ad618d8e7e3bdebecec23aa27f55ad",
        ),
        "x86_64-unknown-linux-gnu": struct(
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.8/bun-linux-x64.zip",
            strip_prefix = "bun-linux-x64",
            sha256 = "de76be16f3d4f1b06005f0127a063a8cda1b35ff63d8e180316d1954953ea055",
        ),
    },
}
