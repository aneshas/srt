defmodule Srt do
  @moduledoc """
  Documentation for `Srt`.
  """

  alias HtmlSanitizeEx.Scrubber

  @positions_regex ~r/{\\an(?<pos>\d+)}/

  @type opts :: [
          strip_tags: boolean()
        ]

  @spec decode(String.t(), opts()) :: [Srt.Subtitle.t() | {:error, String.t()}]
  def decode(data, opts \\ []) do
    lines(data)
    |> Enum.map(&decode_subtitle(&1, opts))
  end

  @spec decode(String.t(), opts()) :: [Srt.Subtitle.t()]
  def decode!(data, opts \\ []) do
    lines(data)
    |> Enum.map(&decode_subtitle!(&1, opts))
  end

  defp lines(data) do
    data
    |> String.replace("\r\n", "\n")
    |> String.split("\n\n")
    |> Enum.filter(&(String.trim(&1) != ""))
  end

  # TODO:
  # handle file format and different line breaks - assume utf-8 ?: https://github.com/san650/subtitle/blob/master/lib/subtitle/sub_rip/parser.ex
  # - error on duplicate index
  # ignore unofficially, text coordinates can be specified at the end of the timestamp line as X1:… X2:… Y1:… Y2:…
  # https://forum.doom9.org/archive/index.php/t-86664.html
  # add example tests

  defp decode_subtitle(data, opts) do
    try do
      decode_subtitle!(data, opts)
    rescue
      error ->
        {:error, Exception.message(error)}
    end
  end

  defp decode_subtitle!(data, opts) do
    [index, start_end | text] =
      data
      |> String.split("\n")

    [from, to] =
      String.replace(start_end, " ", "")
      |> String.split("-->")

    from = String.replace(from, ",", ".")
    to = String.replace(to, ",", ".")

    {text, text_stripped} = text |> clean_tags(opts)
    {text, positions} = parse_positions(text)

    {:ok,
     %Srt.Subtitle{
       index: String.to_integer(index),
       start: Time.from_iso8601!("#{from}Z"),
       end: Time.from_iso8601!("#{to}Z"),
       text: text,
       text_stripped: text_stripped,
       text_positions: positions
     }}
  end

  defp parse_positions(lines) do
    positions =
      lines
      |> Enum.map(&Regex.named_captures(@positions_regex, &1))
      |> Enum.map(&pos/1)

    lines = for line <- lines, do: Regex.replace(@positions_regex, line, "")

    {lines, positions}
  end

  defp pos(%{"pos" => pos}), do: String.to_integer(pos)
  defp pos(nil), do: 0

  @tags [
    "b",
    "i",
    "u"
  ]

  defp clean_tags(text, opts) do
    scrubbed =
      text
      |> Enum.map(&clean_line/1)
      |> Enum.join("\n")
      |> String.trim_trailing("\n")
      |> Scrubber.scrub(Srt.Scrubber)

    {scrubbed |> String.split("\n"), scrubbed |> strip_tags(opts)}
  end

  defp strip_tags(text, [:strip_tags]) do
    Regex.replace(
      @positions_regex,
      HtmlSanitizeEx.strip_tags(text),
      ""
    )
    |> String.split("\n")
  end

  defp strip_tags(_text, _opts), do: nil

  defp clean_line(line) do
    @tags
    |> Enum.reduce(line, fn tag, acc ->
      String.replace(acc, "{#{tag}}", "<#{tag}>")
      |> String.replace("{#{String.upcase(tag)}}", "<#{tag}>")
      |> String.replace("{/#{tag}}", "</#{tag}>")
      |> String.replace("{/#{String.upcase(tag)}}", "</#{tag}>")
    end)
  end
end
