defmodule Adept.Svg.MixProject do
  use Mix.Project

  @version "0.3.0"
  @url "https://github.com/adept-bits/adept_svg"

  def project do
    [
      app: :adept_svg,
      name: "Adept.Svg",
      description: "A simple and fast in-line SVG library and renderer for web applications",
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: [:dev, :docs]}
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2"],
      maintainers: ["Boyd Multerer"],
      links: %{"GitHub" => @url}
    }
  end

  def docs do
    [
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: @url,
      main: "readme"
    ]
  end
end
