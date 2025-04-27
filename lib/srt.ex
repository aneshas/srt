defmodule Srt do
  @moduledoc """
  Decode SRT subtitles.
  """

  alias HtmlSanitizeEx.Scrubber

  @type opts :: {:strip_tags, boolean()}

  @doc """
  Decode SRT subtitles and optionally strip HTML tags.
  Invalid html tags are preserved always stripped.

  {\\an1} caption position is parsed and returned in `text_positions` field as a list of integers (default is 0).

  This coord format is not supported:
  00:00:33,920 --> 00:00:37,360 X1:100 Y1:100 X2:200 Y2:200

  Any parsing errors are returned as {:error, String.t()} for all invalid subtitle entries.
  If you want to raise an error for invalid subtitles, use `decode!/1`.

  ## Options

  * `:strip_tags` - When true, strip HTML tags from the text. Original tags are preserved
  and stripped text is returned in `text_stripped` field.

  ## Examples

  Decode SRT subtitles and parse errors.

      iex> \"\"\"
      ...> 1
      ...> 00:00:33,920 --> 00:00:37,360
      ...> <i>Long ago,
      ...> the plains of East Africa</i>
      ...>
      ...> 2
      ...> 00:00:37,440 --> 00:00:40,440
      ...> <i>were home to our distant ancestors.</i>
      ...>
      ...> 3
      ...> 00.00.40,440 --> 00:00:43,440
      ...> \"\"\"
      ...> |> Srt.decode()
      [
        ok: %Srt.Subtitle{
          index: 1,
          start: ~T[00:00:33.920],
          end: ~T[00:00:37.360],
          text: ["<i>Long ago,", "the plains of East Africa</i>"],
          text_positions: [0, 0]
        },
        ok: %Srt.Subtitle{
          index: 2,
          start: ~T[00:00:37.440],
          end: ~T[00:00:40.440],
          text: ["<i>were home to our distant ancestors.</i>"],
          text_positions: [0]
        },
        error: "cannot parse \\"00.00.40.440Z\\" as time, reason: :invalid_format"
      ]

  """
  @spec decode(String.t(), [opts()]) :: [Srt.Subtitle.t() | {:error, String.t()}]
  def decode(data, opts \\ []) do
    lines(data)
    |> Enum.map(&decode_subtitle(&1, opts))
  end

  @doc """
  See `decode/2`.
  """
  @spec decode!(String.t(), [opts()]) :: [Srt.Subtitle.t()]
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

    [from, _, to | _] = String.split(start_end, " ")

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

  @positions_regex ~r/{\\an(?<pos>\d+)}/

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

    strip_tags = opts |> Keyword.get(:strip_tags, false)

    {scrubbed |> String.split("\n"), scrubbed |> strip_tags(strip_tags)}
  end

  defp strip_tags(text, true) do
    Regex.replace(
      @positions_regex,
      HtmlSanitizeEx.strip_tags(text),
      ""
    )
    |> String.split("\n")
  end

  defp strip_tags(_text, false), do: nil

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
