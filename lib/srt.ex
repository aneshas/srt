defmodule Srt do
  @moduledoc """
  Documentation for `Srt`.
  """

  alias HtmlSanitizeEx.Scrubber

  def decode(data, opts \\ []) do
    data
    |> String.replace("\r\n", "\n")
    |> String.split("\n\n")
    |> Enum.map(&decode_subtitle(opts, &1))
  end

  # TODO:
  # handle empty lines at the end of the file
  # add decode!
  # handle file format and different line breaks - assume utf-8 ?: https://github.com/san650/subtitle/blob/master/lib/subtitle/sub_rip/parser.ex
  # handle errors
  # - error on duplicate index
  # ignore unofficially, text coordinates can be specified at the end of the timestamp line as X1:… X2:… Y1:… Y2:…
  # https://forum.doom9.org/archive/index.php/t-86664.html
  # add example tests

  # Parse and strip positional tags:
  # Other common values are:
  # an1 = bottom left
  # an2 = bottom center
  # an3 = bottom right
  # an4 = middle left
  # an5 = middle center
  # an6 = middle right
  # an7 = top left
  # an8 = top center
  # an9 = top right

  # options
  defp decode_subtitle(opts, data) do
    try do
      decode_subtitle!(opts, data)
    rescue
      error ->
        {:error, Exception.message(error)}
    end
  end

  defp decode_subtitle!(opts, data) do
    [index, start_end | text] =
      data
      |> String.split("\n")

    [from, to] =
      String.replace(start_end, " ", "")
      |> String.split("-->")

    from = String.replace(from, ",", ".")
    to = String.replace(to, ",", ".")

    {text, text_stripped} = text |> clean_tags(opts)

    {:ok,
     %Srt.Subtitle{
       index: String.to_integer(index),
       start: Time.from_iso8601!("#{from}Z"),
       end: Time.from_iso8601!("#{to}Z"),
       text: text,
       text_stripped: text_stripped
     }}
  end

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
      |> Scrubber.scrub(Srt.Scrubber)

    {scrubbed |> String.split("\n"), scrubbed |> strip_tags(opts)}
  end

  defp strip_tags(text, [:strip_tags]) do
    HtmlSanitizeEx.strip_tags(text)
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
