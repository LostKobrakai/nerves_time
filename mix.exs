defmodule NervesTime.MixProject do
  use Mix.Project

  @version "0.4.4"
  @source_url "https://github.com/nerves-time/nerves_time"

  def project do
    [
      app: :nerves_time,
      version: @version,
      elixir: "~> 1.7",
      description: description(),
      package: package(),
      source_url: @source_url,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      make_error_message: "",
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
      ],
      deps: deps(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NervesTime.Application, []}
    ]
  end

  defp description do
    "Keep time in sync on Nerves devices"
  end

  defp package do
    %{
      files: [
        "lib",
        "src/*.[ch]",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "Makefile"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp deps do
    [
      {:muontrap, "~> 1.0 or ~> 0.5"},
      {:elixir_make, "~> 0.6", runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
