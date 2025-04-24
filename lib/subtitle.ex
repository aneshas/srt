defmodule Srt.Subtitle do
  defstruct index: 0,
            start: ~T[00:00:00.000],
            end: ~T[00:00:00.000],
            text: [],
            text_stripped: nil,
            text_positions: nil
end
