defmodule Srt.MixProject do
  use Mix.Project

  def project do
    [
      app: :srt,
      description: "Decode SRT subtitles.",
      package: package(),
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:html_sanitize_ex, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      name: "srt",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/aneshas/srt"}
    ]
  end
end
