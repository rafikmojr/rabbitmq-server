load(
    "@bazel_skylib//rules:common_settings.bzl",
    "BuildSettingInfo",
)
load(
    "@rules_erlang//tools:erlang_toolchain.bzl",
    "erlang_dirs",
    "maybe_symlink_erlang",
)

ElixirInfo = provider(
    doc = "A Home directory of a built Elixir",
    fields = ["release_dir", "elixir_home"],
)

def _find_root(sources):
    dirs = [s.dirname for s in sources]
    root = dirs[0]
    for d in dirs:
        if d == "":
            fail("unexpectedly empty dirname")
        if root.startswith(d):
            root = d
        elif d.startswith(root):
            pass
        else:
            fail("{} and {} do not share a common root".format(d, root))
    return root

def _impl(ctx):
    release_dir = ctx.actions.declare_directory(ctx.label.name + "_release")
    build_dir = ctx.actions.declare_directory(ctx.label.name + "_build")

    (erlang_home, _, runfiles) = erlang_dirs(ctx)

    inputs = depset(
        direct = ctx.files.sources,
        transitive = [runfiles.files],
    )

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [release_dir, build_dir],
        command = """set -euo pipefail

{maybe_symlink_erlang}

export PATH="{erlang_home}"/bin:${{PATH}}

ABS_BUILD_DIR=$PWD/{build_path}
ABS_RELEASE_DIR=$PWD/{release_path}

cp -rp {source_path}/* $ABS_BUILD_DIR

cd $ABS_BUILD_DIR

make

cp -r bin $ABS_RELEASE_DIR/
cp -r lib $ABS_RELEASE_DIR/
""".format(
            maybe_symlink_erlang = maybe_symlink_erlang(ctx),
            erlang_home = erlang_home,
            source_path = _find_root(ctx.files.sources),
            build_path = build_dir.path,
            release_path = release_dir.path,
        ),
        mnemonic = "ELIXIR",
        progress_message = "Compiling elixir from source",
    )

    return [
        DefaultInfo(
            files = depset([release_dir]),
        ),
        ctx.toolchains["@rules_erlang//tools:toolchain_type"].otpinfo,
        ElixirInfo(
            release_dir = release_dir,
            elixir_home = None,
        ),
    ]

elixir_build = rule(
    implementation = _impl,
    attrs = {
        "sources": attr.label_list(allow_files = True, mandatory = True),
    },
    toolchains = ["@rules_erlang//tools:toolchain_type"],
)

def _elixir_external_impl(ctx):
    elixir_home = ctx.attr._elixir_home[BuildSettingInfo].value

    status_file = ctx.actions.declare_file(ctx.label.name + "_status")

    ctx.actions.run_shell(
        inputs = [],
        outputs = [status_file],
        command = """set -euo pipefail

if [ -n "{elixir_home}" ]; then
    "{elixir_home}"/bin/iex --version >> {status_path}
else
    echo "none" >> {status_path}
fi
""".format(
            elixir_home = elixir_home,
            status_path = status_file.path,
        ),
        mnemonic = "ELIXIR",
        progress_message = "Validating elixir at {}".format(elixir_home),
    )

    return [
        DefaultInfo(
            files = depset([status_file]),
        ),
        ctx.toolchains["@rules_erlang//tools:toolchain_type"].otpinfo,
        ElixirInfo(
            release_dir = None,
            elixir_home = elixir_home,
        ),
    ]

elixir_external = rule(
    implementation = _elixir_external_impl,
    attrs = {
        "_elixir_home": attr.label(default = Label("//:elixir_home")),
    },
    toolchains = ["@rules_erlang//tools:toolchain_type"],
)
