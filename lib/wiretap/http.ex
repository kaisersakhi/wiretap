defmodule Wiretap.Http do
  def handle(request) do
    request
    |> parse
    |> route
    |> response
  end

  def parse(_request) do
  end

  def route(_con) do
  end

  def response(_conn) do
  end
end

# <Request-Line>\r\n
# <Headers>\r\n
# \r\n # This CRLF is mandatory even when body is empty
# <Optional Body>

# Request-Line
# METHOD SP REQUEST-TARGET SP HTTP-VERSION\r\n
