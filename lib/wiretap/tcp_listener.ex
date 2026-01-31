defmodule Wiretap.TCPListener do
  require Logger

  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  @spec init(char()) :: {:ok, port() | {:"$inet", atom(), any()}}
  def init(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])

    Logger.debug("Started server on port: #{port}")

    send(self(), :accept)
    {:ok, socket}
  end

  def handle_info(:accept, socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    Logger.debug("Accepted : #{inspect(client)}")

    Task.start_link(fn -> handle_client(client) end)
    send(self(), :accept)

    {:noreply, socket}
  end

  def handle_client(socket) do
    :gen_tcp.send(socket, "Hello\r\n")
    :gen_tcp.close(socket)
  end
end
