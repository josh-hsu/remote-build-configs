
REMOTE_EXEC_CONSTRAINTS = [
    "@platforms//cpu:x86_64",
    "@platforms//os:linux",
    "//platforms:bb-server-amd64-01",
]

REMOTE_TARGET_CONSTRAINTS_AMD64 = [
    "@platforms//cpu:x86_64",
    "@platforms//os:linux",
]

REMOTE_TARGET_CONSTRAINTS_ARM64 = [
    "@platforms//cpu:aarch64",
    "@platforms//os:linux",
]
