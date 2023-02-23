defmodule SopsConfigProvider.MixProject do
  @moduledoc """
    mix for sops_config_provider
  """
  use Mix.Project

  def project do
    [
      app: :sops_config_provider,
      version: "0.1.0",
      elixir: "~> 1.13",
      compilers: [:domo_compiler] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test,
        "test.watch": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps(),
      package: package(),
      name: "SopsConfigProvider",
      description: description(),
      source_url: "https://github.com/drselump14/sops_config_provider"
    ]
  end

  defp description do
    "Decrypt soap file and load it to Application config"
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:domo, "~> 1.5"},
      {:decimal, "~> 2.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.19.0", only: :dev},
      {:excoveralls, "~> 0.10", only: [:dev, :test]},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:ex_machina, "~> 2.7.0"},
      {:ex_unit_notifier, "~> 1.2", only: :test},
      {:faker, "~> 0.17", only: [:dev, :test]},
      {:gradient, github: "esl/gradient", only: [:dev], runtime: false},
      {:git_hooks, "~> 0.7.0", only: [:dev], runtime: false},
      {:jason, "~> 1.4"},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.0", only: [:test]},
      {:typed_struct, "~> 0.3.0"},
      {:yaml_elixir, "~> 2.9.0"}
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE.md),
      maintainers: ["Slamet Kristanto"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/drselump14/sops_config_provider"
      }
    ]
  end
end
