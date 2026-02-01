defmodule Wiretap.Response do
  defstruct [:status, :headers, :body]

  def to_string(%__MODULE__{status: status, headers: headers, body: body}) do
    [build_status_line(status), build_headers(headers), build_body(body)]
    |> IO.iodata_to_binary()
  end

  defp build_headers(headers) do
    Enum.map(headers, fn {key, value} -> "#{key}: #{value}\r\n" end)
    |> IO.iodata_to_binary()
  end

  defp build_body(body) do
    body
    |> IO.iodata_to_binary()
  end

  defp status_line(status) do
    case status do
      200 -> "200 OK"
      404 -> "404 Not Found"
      500 -> "500 Internal Server Error"
      _ -> "200 OK"
    end
  end

  defp build_status_line(status) do
    "HTTP/1.1 #{status_line(status)}\r\n"
    |> IO.iodata_to_binary()
  end
end
