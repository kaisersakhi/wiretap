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

  def feed(%__MODULE__{} = parser, data) do
    parser = %{parser | buffer: parser.buffer <> data}
    process(parser)
  end

  defp process(%{state: :headers} = parser) do
    new_parser = parse_headers(parser)
    if new_parser.state == :body do
      process(new_parser)
    else
      {:more, new_parser}
    end
  end

  defp process(%{state: :body} = parser) do
    parse_body(parser)
  end

  defp process(parser), do: {:more, parser}

  defp parse_headers(%__MODULE__{state: :headers} = parser) do
    case String.split(parser.buffer, "\r\n\r\n", parts: 2) do
      [headers_str, _body_str] ->
        headers = parse_headers_str(headers_str)
        %{parser | headers: headers, state: :body, content_length: headers |> Map.get("content-length", "0") |> String.to_integer()}

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
    body_size = byte_size(body)
    body(parser, body, body_size)
  end

  defp body(%__MODULE__{state: :body, content_length: content_length} = parser, body, body_size) when body_size == content_length do
    request = prepare_request(parser, body)

    {:done, request, "", %{parser | state: :done}}
  end

  defp body(%__MODULE__{state: :body, content_length: content_length} = parser, _body, body_size) when body_size < content_length do
    {:more, parser}
  end

  defp body(%__MODULE__{state: :body, content_length: content_length} = parser, body, body_size) when body_size > content_length do
    <<body::binary-size(content_length), rest::binary>> = body

    request = prepare_request(parser, body)

    {:done, request, rest, %{parser | state: :done}}
  end

  defp prepare_request(parser, body) do
    %Wiretap.Request{
      method: parser.headers["method"],
      path: parser.headers["path"],
      version: parser.headers["http_version"],
      headers: parser.headers,
      body: body
    }
  end
end
