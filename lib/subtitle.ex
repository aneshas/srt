defmodule Srt.Subtitle do
  @type t :: %__MODULE__{
          index: integer(),
          start: Time.t(),
          end: Time.t(),
          text: [String.t()],
          text_stripped: [String.t()] | nil,
          text_positions: [integer() | nil] | nil
        }

  defstruct index: 0,
            # Start time of the subtitle.
            start: ~T[00:00:00.000],

            # End time of the subtitle.
            end: ~T[00:00:00.000],

            # A list of text lines.
            text: [],

            # A list of stripped text lines if `strip_tags` option is provided.
            text_stripped: nil,

            # A list of positions for each line of text.
            # The position is the index of the line in the text.
            # The first line has index 0, the second line has index 1, etc.
            text_positions: nil
end
