defmodule Wiretap.Parser do
  @type t :: %__MODULE__{
          state: :headers | :body | :done,
          buffer: binary(),
          headers: map() | nil,
          content_length: non_neg_integer()
        }

  defstruct [
    state: :headers,
    buffer: "",
    headers: nil,
    content_length: 0
  ]

  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @spec feed(t(), binary()) :: t()
  def feed(%__MODULE__{} = parser, data) do
    parser = %{parser | buffer: parser.buffer <> data}

    case parser.state do
      :headers -> parse_headers(parser)
      :body -> parse_body(parser)
      _ -> parser
    end
  end

  defp parse_headers(%__MODULE__{state: :headers} = parser) do
    case String.split(parser.buffer, "\r\n\r\n", parts: 2) do
      [_headers, _body] ->
        # TODO: Implement header parsing
        parser

      [_incomplete] ->
        parser
    end
  end

  defp parse_body(%__MODULE__{state: :body} = parser) do
    # TODO: Implement body parsing
    parser
  end
end
