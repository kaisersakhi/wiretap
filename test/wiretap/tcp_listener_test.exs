defmodule Wiretap.TCPListenerTest do
  use ExUnit.Case

  # Ideally we would start our own listener here on a random port,
  # but the current implementation enforces a singleton name.
  # So we test the one started by the application on port 4010.
  @port 4010

  test "accepts connections and responds to HTTP requests" do
    # Connect to the server
    opts = [:binary, packet: :raw, active: false]
    {:ok, socket} = :gen_tcp.connect(~c"localhost", @port, opts)

    # Send a simple HTTP request
    request = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"
    :ok = :gen_tcp.send(socket, request)

    # Receive the response
    # The server might close the connection or keep it open.
    # Our current implementation just sends a response.
    {:ok, response} = :gen_tcp.recv(socket, 0)

    assert response =~ "HTTP/1.1 200 OK"
    assert response =~ "Hello, World!"

    :gen_tcp.close(socket)
  end
end
