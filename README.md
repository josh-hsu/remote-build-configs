# Importing Buildbarn into Projects

These instructions assume your project is using Bazel Modules (bzlmod).

## Prerequisites

* Bazel (version supporting bzlmod recommended, e.g., 6.0+).
* A running BuildBarn instance (or a compatible remote execution service).

## 1. Add as a Bazel Dependency

In your project's `MODULE.bazel` file, add `remote_build_configs` as a dependency:

```bazel
# Add the following dependency to your_project/MODULE.bazel

bazel_dep(name = "remote_build_configs", version = "0.0.1")

local_path_override(
    module_name = "remote_build_configs",
    path = "../remote-build-configs",
)
```

> TODO: the module `remote_build_configs` can be further deployed as single project in GitHub.

## 2. Configure `.bazelrc`

In your project's `.bazelrc` file, create build configurations to use these platforms and toolchains.

```bazel
# your_project/.bazelrc

# --- Common Remote Execution Settings (adjust as needed) ---
build:remote-exec --remote_executor=grpc://localhost:8980
build:remote-exec --remote_instance_name=fuse
build:remote-exec --jobs=64
build:remote-exec --remote_download_toplevel

# --- Configuration for Remote ARM64 Build ---
build:remote-arm64 --config=remote-exec
build:remote-arm64 --extra_execution_platforms=@remote_build_configs//platforms:amd64-exec-platform
build:remote-arm64 --platforms=@remote_build_configs//platforms:target-linux-arm64
build:remote-arm64 --extra_toolchains=@remote_build_configs//toolchains:cc-toolchain-k8-arm64

# --- Configuration for Remote AMD64 Build ---
build:remote-amd64 --config=remote-exec
build:remote-amd64 --extra_execution_platforms=@remote_build_configs//platforms:amd64-exec-platform
build:remote-amd64 --platforms=@remote_build_configs//platforms:target-linux-amd64
build:remote-amd64 --extra_toolchains=@remote_build_configs//toolchains:cc-toolchain-k8
```

## 3. Build Your Project

You can now build your project using the defined configurations:

For ARM64 remote build:

```bash
bazel build //your/target/... --config=remote-arm64
```

For AMD64 remote build:

```bash
bazel build //your/target/... --config=remote-amd64
```
