defmodule Wiretap.TCPListener do
  require Logger

  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  @spec init(char()) :: {:ok, port() | {:"$inet", atom(), any()}}
  def init(port) do
    # Listen on the given port.
    # [:binary, packet: :raw, active: false, reuseaddr: true]
    # - :binary -> Receive data as binaries (not lists of integers)
    # - packet: :raw -> We handle the framing manually (no specific packet structure expected)
    # - active: false -> We must manually read data using :gen_tcp.recv/2. This provides backpressure.
    # - reuseaddr: true -> Allows us to reuse the address immediately after the app stops (prevents "address already in use" errors)
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])

    Logger.debug("Started server on port: #{port}")

    # CRITICAL: We do NOT want to block `init/1`.
    # `init/1` must return quickly so the supervisor knows this process started successfully.
    # If we called `:gen_tcp.accept(socket)` here, it would block the supervision tree startup.
    # Instead, we send ourselves a message to start accepting connection *after* initialization is done.
    send(self(), :accept)
    # Socket is stored in state, will be used by `handle_info/2` to accept connections.
    {:ok, socket}
  end

  def handle_info(:accept, socket) do
    # Block and wait for a client connection.
    # Since this is in `handle_info`, it doesn't block the Application startup,
    # but it DOES block this specific GenServer process.
    # This is fine because this process's *only* job is to accept new connections.
    {:ok, client} = :gen_tcp.accept(socket)

    Logger.debug("Accepted : #{inspect(client)}")

    # CONCURRENCY:
    # We spawn a separate Task to handle the client connection.
    # This ensures that this `TCPListener` process can immediately loop back
    # and accept the NEXT connection without waiting for this client to finish.
    # If we handled the client here directly, no other user could connect until we finished serving this one.
    Task.start_link(fn -> handle_client(client) end)

    # Loop: Send ourselves another message to accept the next connection.
    send(self(), :accept)

    {:noreply, socket}
  end

  def handle_client(socket) do
    :gen_tcp.send(socket, "Hello\r\n")
    :gen_tcp.close(socket)
  end
end
