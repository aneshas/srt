defmodule SrtTest do
  use ExUnit.Case

  import Srt, only: [decode: 1, decode: 2, decode!: 1]

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
      |> decode!()

    assert subtitles == [
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
             }
           ]
  end

  test "decode with positions" do
    subtitles =
      """
      1
      00:00:33,920 --> 00:00:37,360
      {\\an1}<i>Long ago,
      {\\an8}the plains of East Africa</i>

      2
      00:00:37,440 --> 00:00:40,440
      <i>were home to our distant ancestors.</i>
      {\\an2}<i>were home to our distant ancestors.</i>
      """
      |> decode(strip_tags: true)

    assert subtitles == [
             ok: %Srt.Subtitle{
               index: 1,
               start: ~T[00:00:33.920],
               end: ~T[00:00:37.360],
               text: ["<i>Long ago,", "the plains of East Africa</i>"],
               text_stripped: ["Long ago,", "the plains of East Africa"],
               text_positions: [1, 8]
             },
             ok: %Srt.Subtitle{
               index: 2,
               start: ~T[00:00:37.440],
               end: ~T[00:00:40.440],
               text: [
                 "<i>were home to our distant ancestors.</i>",
                 "<i>were home to our distant ancestors.</i>"
               ],
               text_stripped: [
                 "were home to our distant ancestors.",
                 "were home to our distant ancestors."
               ],
               text_positions: [0, 2]
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
                 "alert('xss')"
               ],
               text_positions: [0, 0, 0, 0, 0]
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
      |> decode(strip_tags: true)

    assert subtitles == [
             ok: %Srt.Subtitle{
               index: 1,
               start: ~T[00:00:33.920],
               end: ~T[00:00:37.360],
               text: [
                 "<i>Long</i> <u>ago,</u> <b>the plains</b>",
                 "<i>Long</i> <u>ago,</u> <b>the plains</b>"
               ],
               text_stripped: [
                 "Long ago, the plains",
                 "Long ago, the plains"
               ],
               text_positions: [0, 0]
             }
           ]
  end

  test "decode ignore coords" do
    subtitles =
      """
      1
      00:00:33,920 --> 00:00:37,360 X1:100 Y1:100 X2:200 Y2:200
      Foo
      """
      |> decode()

    assert subtitles == [
             ok: %Srt.Subtitle{
               index: 1,
               start: ~T[00:00:33.920],
               end: ~T[00:00:37.360],
               text: ["Foo"],
               text_positions: [0]
             }
           ]
  end

  test "decode with error" do
    subtitles =
      """
      1
      00:00:33,920 --> 00:0037,360
      {i}Long{/i} {u}ago,{/u} {b}the plains{/b}
      {I}Long{/I} {U}ago,{/U} {B}the plains{/B}
      """
      |> decode(strip_tags: true)

    assert subtitles == [error: "cannot parse \"00:0037.360Z\" as time, reason: :invalid_format"]
  end

  test "decode with bang" do
    assert_raise ArgumentError, fn ->
      """
      1
      00:00:33,920 --> 00:0037,360
      {i}Long{/i} {u}ago,{/u} {b}the plains{/b}
      {I}Long{/I} {U}ago,{/U} {B}the plains{/B}
      """
      |> decode!()
    end
  end

  test "smoke" do
    subtitles =
      @file_path
      |> Path.join("secrets.srt")
      |> File.read!()
      |> decode(strip_tags: true)

    IO.inspect(subtitles)
  end
end
