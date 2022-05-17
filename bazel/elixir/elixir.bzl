load(
    ":elixir_build.bzl",
    "elixir_build",
)
load(
    ":elixir_toolchain.bzl",
    "elixir_toolchain",
)

def elixir_home():
    elixir_build(
        name = "elixir_build",
        sources = native.glob(
            ["**/*"],
            exclude = ["BUILD.bazel", "WORKSPACE.bazel"],
        ),
    )

    elixir_toolchain(
        name = "elixir",
        elixir = ":elixir_build",
    )

    native.toolchain(
        name = "elixir_toolchain",
        toolchain = ":elixir",
        toolchain_type = "@rabbitmq-server//bazel/elixir:toolchain_type",
        visibility = ["//visibility:public"],
    )
