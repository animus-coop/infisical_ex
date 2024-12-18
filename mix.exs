defmodule InfisicalEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :infisical_ex,
      version: "0.1.0",
      elixir: "~> 1.17",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "InfisicalEx",
      source_url: "https://github.com/animus-coop/infisical_ex"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.2.1"},
      {:jason, "~> 1.4.4"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.35.1", [only: :dev, hex: "ex_doc", repo: "hexpm"]}
    ]
  end

  defp description() do
    "A client to get secrets from Infisical project and use it on runtime configs."
  end

  defp package() do
    [
      name: "infisical_ex",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/animus-coop/infisical_ex"}
    ]
  end
end
