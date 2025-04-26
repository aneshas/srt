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
            start: ~T[00:00:00.000],
            end: ~T[00:00:00.000],
            text: [],
            text_stripped: nil,
            text_positions: nil
end
