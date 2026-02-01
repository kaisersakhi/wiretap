defmodule Wiretap.Parser do
  # <method> <request-target> <http-version>\r\n
  # <header-name>: <header-value>\r\n
  # <header-name>: <header-value>\r\n
  # ...\r\n
  # <message-body>

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
    content_length: 0,
  ]

  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @spec feed(t(), binary()) :: t()
  def feed(%__MODULE__{} = parser, data) do
    parser = %{parser | buffer: parser.buffer <> data}

    parser = case parser.state do
      :headers -> parse_headers(parser)
      :body -> parse_body(parser)
      _ -> parser
    end

    parser
  end

  defp parse_headers(%__MODULE__{state: :headers} = parser) do
    case String.split(parser.buffer, "\r\n\r\n", parts: 2) do
      [headers_str, _body_str] ->
        headers = parse_headers_str(headers_str)
        %{parser | headers: headers, state: :body, content_length: headers["content-length"]}

      [_incomplete] ->
        parser
    end
  end

  @spec parse_headers_str(binary()) :: %{
          :http_version => binary(),
          :method => binary(),
          :path => binary(),
          optional(any()) => any()
        }
  def parse_headers_str(headers_str) do
    [request_line | header_lines] = String.split(headers_str, "\r\n")

    [method, path, http_version] = String.split(request_line, " ", parts: 3)

    header_lines
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [key, value] ->
          Map.put(acc, String.downcase(key), String.trim(value))
        _ -> acc
      end
    end)
    |> Map.put("method", method)
    |> Map.put("path", path)
    |> Map.put("http_version", http_version)
  end

  defp parse_body(%__MODULE__{state: :body} = parser) do
    body = parser.buffer |> String.split("\r\n\r\n", parts: 2) |> List.last()

    if byte_size(body) == parser.content_length |> String.to_integer() do
      request = %Wiretap.Request{
        method: parser.headers["method"],
        path: parser.headers["path"],
        version: parser.headers["http_version"],
        headers: parser.headers,
        body: body
      }

      {:done, request, "", %{parser | state: :done}}
    else
      parser
    end
  end
end
