load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)
load(
    "@rules_erlang//bzlmod:otp.bzl",
    "merge_archive",
)
load(
    "@rules_erlang//:hex_archive.bzl",
    "hex_archive",
)

def _installation_suffix(erlang_installation):
    wn = erlang_installation.workspace_name
    return wn.removeprefix("rules_erlang").removeprefix(".erlang_package.")

def _merge_package(props, packages):
    for p in packages:
        if props["name"] == p["name"]:
            if props != p:
                fail("package conflict: {} and {}".format(props, p))
            return packages
    return packages + [props]

def _impl(ctx):
    elixir_archives = []
    for mod in ctx.modules:
        for release in mod.tags.elixir_github_release:
            name = "elixir_{}".format(release.version)
            url = "https://github.com/elixir-lang/elixir/archive/refs/tags/v{}.zip".format(release.version)
            props = {
                "name": name,
                "url": url,
                "strip_prefix": "elixir-{}".format(release.version),
                "sha256": release.sha256,
            }
            elixir_archives = merge_archive(props, elixir_archives)

    for props in elixir_archives:
        http_archive(
            build_file_content = ELIXIR_BUILD_FILE_CONTENT,
            **props
        )

    hex_packages = []
    for mod in ctx.modules:
        for package in mod.tags.hex_package:
            name = "elixir_{}".format(release.version)
            url = "https://github.com/elixir-lang/elixir/archive/refs/tags/v{}.zip".format(release.version)
            props = {
                "name": package.name,
                "version": package.version,
                "sha256": package.sha256,
                "deps": package.deps,
                "build_file_content": package.build_file_content,
                "patch_cmds": package.patch_cmds,
            }
            hex_packages = _merge_package(props, hex_packages)

    for props in hex_packages:
        name = props["name"]
        deps = props.pop("deps")
        if props["build_file_content"] == "":
            props["build_file_content"] = MIX_PACKAGE_BUILD_FILE_CONTENT.format(
                name = name,
                deps = deps,
            )
        hex_archive(
            package_name = name,
            **props
        )

elixir_github_release = tag_class(attrs = {
    "version": attr.string(),
    "sha256": attr.string(),
})

hex_package = tag_class(attrs = {
    "name": attr.string(),
    "version": attr.string(),
    "sha256": attr.string(),
    "deps": attr.string_list(),
    "build_file_content": attr.string(),
    "patch_cmds": attr.string_list(),
})

elixir = module_extension(
    implementation = _impl,
    tag_classes = {
        "elixir_github_release": elixir_github_release,
        "hex_package": hex_package,
    },
)

ELIXIR_BUILD_FILE_CONTENT = """load(
    "@rabbitmq-server//bazel/elixir:elixir.bzl",
    "elixir_home",
)

elixir_home()
"""

MIX_PACKAGE_BUILD_FILE_CONTENT = """load(
    "@rabbitmq-server//bazel/mix:mix_app.bzl",
    "mix_app",
)

filegroup(
    name = "srcs",
    srcs = glob([
        "mix.exs",
        "lib/**/*.ex",
    ]),
    visibility = ["//visibility:public"],
)

mix_app(
    name = "elixir_app",
    app_name = "{name}",
    srcs = [":srcs"],
    license_files = glob(["LICENSE*"]),
    deps = {deps},
    visibility = ["//visibility:public"],
)
"""
