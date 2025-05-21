

"""Starlark rules for defining the arm64 C++ toolchain."""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "feature",
    "feature_set",
    "flag_group",
    "flag_set",
    "tool_path",
    "variable_with_value",
    "with_feature_set",
)

all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    # ACTION_NAMES.clif_match, # Uncomment if used
    ACTION_NAMES.lto_backend,
]

all_cpp_compile_actions = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    # ACTION_NAMES.clif_match, # Uncomment if used
]

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

lto_index_actions = [
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

def _impl(ctx):
    tool_paths = [
        tool_path(name = "gcc", path = "/usr/bin/aarch64-linux-gnu-gcc"), # Compiler
        tool_path(name = "cpp", path = "/usr/bin/aarch64-linux-gnu-cpp"), # Preprocessor
        tool_path(name = "gcov", path = "/usr/bin/aarch64-linux-gnu-gcov"), # Or just "gcov"
        tool_path(name = "ld", path = "/usr/bin/aarch64-linux-gnu-ld"),
        tool_path(name = "ar", path = "/usr/bin/aarch64-linux-gnu-ar"),
        tool_path(name = "nm", path = "/usr/bin/aarch64-linux-gnu-nm"),
        tool_path(name = "objdump", path = "/usr/bin/aarch64-linux-gnu-objdump"),
        tool_path(name = "strip", path = "/usr/bin/aarch64-linux-gnu-strip"),
        tool_path(name = "objcopy", path = "/usr/bin/aarch64-linux-gnu-objcopy"),
        # tool_path(name = "dwp", path = "/usr/bin/aarch64-linux-gnu-dwp"), # If available
    ]

    # Example flags - adjust these to match your cross-compiler and needs
    _compile_flags = [
        "-U_FORTIFY_SOURCE",
        "-fstack-protector",
        "-Wall",
        "-Wunused-but-set-parameter",
        "-Wno-free-nonheap-object",
        "-fno-omit-frame-pointer",
        # "-march=armv8-a", # Be specific if needed
    ]
    _cxx_flags = ["-std=c++17"] # As requested
    _link_flags = [
        "-fuse-ld=gold", # If using gold linker for aarch64
        "-Wl,-no-as-needed",
        "-Wl,-z,relro,-z,now",
        "-B/usr/aarch64-linux-gnu/bin", # Check if this path is correct for your linker
        "-L/usr/aarch64-linux-gnu/lib", # Check library paths
        "-Wl,--dynamic-linker=/lib/ld-linux-aarch64.so.1", # Typical for glibc aarch64
    ]
    _link_libs = ["-lstdc++", "-lm"]

    _opt_compile_flags = [
        "-g0",
        "-O2",
        "-D_FORTIFY_SOURCE=1", # or 2
        "-DNDEBUG",
        "-ffunction-sections",
        "-fdata-sections",
    ]
    _opt_link_flags = ["-Wl,--gc-sections"]
    _dbg_compile_flags = ["-g"]

    _unfiltered_compile_flags = [
        "-fno-canonical-system-headers",
        "-Wno-builtin-macro-redefined",
        "-D__DATE__=\"redacted\"",
        "-D__TIMESTAMP__=\"redacted\"",
        "-D__TIME__=\"redacted\"",
    ]

    cxx_builtin_include_directories = [
        "/usr/lib/gcc-cross/aarch64-linux-gnu/11/include",
        "/usr/aarch64-linux-gnu/include",
        "/usr/aarch64-linux-gnu/include/c++/11",
        "/usr/aarch64-linux-gnu/include/c++/11/aarch64-linux-gnu",
        "/usr/aarch64-linux-gnu/include/c++/11/backward",
    ]

    # --- Start of features: Adapt from your x86 cc_toolchain_config.bzl ---
    # This is a subset. You MUST copy most features from your working x86 config
    # and adapt flags/paths for arm64.

    supports_pic_feature = feature(name = "supports_pic", enabled = True)
    supports_start_end_lib_feature = feature(name = "supports_start_end_lib", enabled = True)

    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = _compile_flags)],
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = _dbg_compile_flags)],
                with_features = [with_feature_set(features = ["dbg"])],
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = _opt_compile_flags)],
                with_features = [with_feature_set(features = ["opt"])],
            ),
            flag_set(
                actions = all_cpp_compile_actions + [ACTION_NAMES.lto_backend],
                flag_groups = [flag_group(flags = _cxx_flags)],
            ),
        ],
    )

    default_link_flags_feature = feature(
        name = "default_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [flag_group(flags = _link_flags)],
            ),
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [flag_group(flags = _opt_link_flags)],
                with_features = [with_feature_set(features = ["opt"])],
            ),
        ],
    )

    dbg_feature = feature(name = "dbg")
    opt_feature = feature(name = "opt")

    sysroot_feature = feature(
        name = "sysroot",
        enabled = True, # Set to False if not using sysroot for cross-compilation explicitly
        flag_sets = [
            flag_set(
                actions = all_compile_actions + all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["--sysroot=%{sysroot}"],
                        expand_if_available = "sysroot",
                    ),
                ],
            ),
        ],
    )

    user_compile_flags_feature = feature(
        name = "user_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_compile_flags}"],
                        iterate_over = "user_compile_flags",
                        expand_if_available = "user_compile_flags",
                    ),
                ],
            ),
        ],
    )

    unfiltered_compile_flags_feature = feature(
        name = "unfiltered_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = _unfiltered_compile_flags)],
            ),
        ],
    )

    pic_feature = feature(
        name = "pic",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ # Be more specific, like in x86 config
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.cpp_module_compile,
                ],
                flag_groups = [
                    flag_group(flags = ["-fPIC"], expand_if_available = "pic"),
                ],
            ),
        ],
    )

    preprocessor_defines_feature = feature(
        name = "preprocessor_defines",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ # Be more specific
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    # ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-D%{preprocessor_defines}"],
                        iterate_over = "preprocessor_defines",
                    ),
                ],
            ),
        ],
    )

    include_paths_feature = feature(
        name = "include_paths",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ # Be more specific
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    # ACTION_NAMES.clif_match,
                    # ACTION_NAMES.objc_compile,
                    # ACTION_NAMES.objcpp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-iquote", "%{quote_include_paths}"],
                        iterate_over = "quote_include_paths",
                    ),
                    flag_group(
                        flags = ["-I%{include_paths}"],
                        iterate_over = "include_paths",
                    ),
                    flag_group(
                        flags = ["-isystem", "%{system_include_paths}"],
                        iterate_over = "system_include_paths",
                    ),
                ],
            ),
        ],
    )

    libraries_to_link_feature = feature( # CRITICAL FEATURE
        name = "libraries_to_link",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        iterate_over = "libraries_to_link",
                        flag_groups = [ # Copied from x86, generally applicable
                            flag_group(
                                flags = ["-Wl,--start-lib"],
                                expand_if_equal = variable_with_value(name = "libraries_to_link.type", value = "object_file_group"),
                            ),
                            flag_group(
                                flags = ["-Wl,-whole-archive"],
                                expand_if_true = "libraries_to_link.is_whole_archive",
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.object_files}"],
                                iterate_over = "libraries_to_link.object_files",
                                expand_if_equal = variable_with_value(name = "libraries_to_link.type", value = "object_file_group"),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(name = "libraries_to_link.type", value = "object_file"),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(name = "libraries_to_link.type", value = "interface_library"),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(name = "libraries_to_link.type", value = "static_library"),
                            ),
                            flag_group(
                                flags = ["-l%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(name = "libraries_to_link.type", value = "dynamic_library"),
                            ),
                            flag_group(
                                flags = ["-l:%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(name = "libraries_to_link.type", value = "versioned_dynamic_library"),
                            ),
                            flag_group(
                                flags = ["-Wl,-no-whole-archive"],
                                expand_if_true = "libraries_to_link.is_whole_archive",
                            ),
                            flag_group(
                                flags = ["-Wl,--end-lib"],
                                expand_if_equal = variable_with_value(name = "libraries_to_link.type", value = "object_file_group"),
                            ),
                        ],
                        expand_if_available = "libraries_to_link",
                    ),
                    flag_group(
                        flags = ["-Wl,@%{thinlto_param_file}"],
                        expand_if_true = "thinlto_param_file", # If using LTO
                    ),
                ],
            ),
        ],
    )

    user_link_flags_feature = feature( # CRITICAL FEATURE
        name = "user_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_link_flags}"],
                        iterate_over = "user_link_flags",
                        expand_if_available = "user_link_flags",
                    ),
                ] + ([flag_group(flags = _link_libs)] if _link_libs else []),
            ),
        ],
    )

    dependency_file_feature = feature( # CRITICAL FEATURE
        name = "dependency_file",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ # Be more specific
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_compile,
                    # ACTION_NAMES.objc_compile,
                    # ACTION_NAMES.objcpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    # ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-MD", "-MF", "%{dependency_file}"],
                        expand_if_available = "dependency_file",
                    ),
                ],
            ),
        ],
    )

    output_execpath_flags_feature = feature( # CRITICAL FEATURE
        name = "output_execpath_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-o", "%{output_execpath}"],
                        expand_if_available = "output_execpath",
                    ),
                ],
            ),
        ],
    )

    supports_dynamic_linker_feature = feature(name = "supports_dynamic_linker", enabled = True)

    # Add other features from your x86 cc_toolchain_config.bzl as needed, e.g.:
    # coverage_feature, strip_debug_symbols_feature, random_seed_feature,
    # archiver_flags_feature, force_pic_flags_feature, etc.
    # Make sure to adapt flags and actions.

    features = [
        # Basic setup
        supports_pic_feature,
        supports_start_end_lib_feature,
        default_compile_flags_feature,
        default_link_flags_feature,
        dbg_feature,
        opt_feature,
        sysroot_feature, # Enable if you use --sysroot for cross-compilation

        # User flags and inputs
        user_compile_flags_feature,
        unfiltered_compile_flags_feature, # For flags like -D__DATE__
        user_link_flags_feature,
        libraries_to_link_feature, # For linking libraries specified in deps

        # Compiler/Linker mechanics
        pic_feature, # For -fPIC
        preprocessor_defines_feature, # For -D defines from copts
        include_paths_feature, # For -I, -iquote, -isystem
        dependency_file_feature, # For .d file generation
        output_execpath_flags_feature, # For -o <output_file>
        supports_dynamic_linker_feature,

        # Add more based on your x86 version and toolchain capabilities
        # e.g. strip_debug_symbols_feature, coverage_feature, etc.
    ]

    action_configs = [] # Often empty when features cover all actions

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        action_configs = action_configs,
        cxx_builtin_include_directories = cxx_builtin_include_directories,
        toolchain_identifier = "local-arm64",
        host_system_name = "local", # Toolchain tools run on the exec platform (x86_64)
        target_system_name = "aarch64-linux-gnu",
        target_cpu = "aarch64",
        target_libc = "glibc_2.35", # Double-check this matches the actual glibc version for aarch64
        compiler = "gcc",
        abi_version = "aapcs",
        abi_libc_version = "glibc_2.35", # Double-check this
        tool_paths = tool_paths,
    )

arm64_cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {}, # Add attributes here if you want to pass them from BUILD file
    provides = [CcToolchainConfigInfo],
)
