defmodule SrtTest do
  use ExUnit.Case
  doctest Srt

  import Srt, only: [decode: 1, decode: 2]

  @file_path Path.expand("./srt", __DIR__)

  test "decode" do
    subtitles =
      """
      1
      00:00:33,920 --> 00:00:37,360
      <i>Long ago,
      the plains of East Africa</i>

      2
      00:00:37,440 --> 00:00:40,440
      <i>were home to our distant ancestors.</i>
      """
      |> decode()

    assert subtitles == [
             ok: %Srt.Subtitle{
               index: 1,
               start: ~T[00:00:33.920],
               end: ~T[00:00:37.360],
               text: ["<i>Long ago,", "the plains of East Africa</i>"]
             },
             ok: %Srt.Subtitle{
               index: 2,
               start: ~T[00:00:37.440],
               end: ~T[00:00:40.440],
               text: ["<i>were home to our distant ancestors.</i>", ""]
             }
           ]
  end

  test "decode alt tags and sanitize" do
    subtitles =
      """
      1
      00:00:33,920 --> 00:00:37,360
      {i}Long{/i} {u}ago,{/u} {b}the plains{/b}
      {I}Long{/I} {U}ago,{/U} {B}the plains{/B}
      <font color="red">Long ago, the plains</font>
      <form>asdf</form>xx
      <script>alert('xss')</script>
      """
      |> decode()

    assert subtitles == [
             ok: %Srt.Subtitle{
               index: 1,
               start: ~T[00:00:33.920],
               end: ~T[00:00:37.360],
               text: [
                 "<i>Long</i> <u>ago,</u> <b>the plains</b>",
                 "<i>Long</i> <u>ago,</u> <b>the plains</b>",
                 "<font color=\"red\">Long ago, the plains</font>",
                 "asdfxx",
                 "alert('xss')",
                 ""
               ]
             }
           ]
  end

  test "decode strip tags" do
    subtitles =
      """
      1
      00:00:33,920 --> 00:00:37,360
      {i}Long{/i} {u}ago,{/u} {b}the plains{/b}
      {I}Long{/I} {U}ago,{/U} {B}the plains{/B}
      """
      |> decode([:strip_tags])

    assert subtitles == [
             ok: %Srt.Subtitle{
               index: 1,
               start: ~T[00:00:33.920],
               end: ~T[00:00:37.360],
               text: [
                 "<i>Long</i> <u>ago,</u> <b>the plains</b>",
                 "<i>Long</i> <u>ago,</u> <b>the plains</b>",
                 ""
               ],
               text_stripped: [
                 "Long ago, the plains",
                 "Long ago, the plains",
                 ""
               ]
             }
           ]
  end

  test "decode file" do
    subtitles =
      @file_path
      |> Path.join("secrets.srt")
      |> File.read!()
      |> decode()

    # TODO
    # assert no errors
    IO.inspect(subtitles)
  end
end
