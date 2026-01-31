defmodule Wiretap.Supervisor do
  use Supervisor

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  @spec init(any()) ::
          {:ok,
           {%{
              auto_shutdown: :all_significant | :any_significant | :never,
              intensity: non_neg_integer(),
              period: pos_integer(),
              strategy: :one_for_all | :one_for_one | :rest_for_one
            }, [{any(), any(), any(), any(), any(), any()} | map()]}}
  def init(_arg) do
    children = [
      # The TCPListener is a worker that we want to remain alive.
      # If it crashes, this Supervisor will restart it.
      # {Module, arg} is a shorthand for calling Module.start_link(arg)
      {Wiretap.TCPListener, 4010}
    ]

    # strategy: :one_for_one
    # If a child process terminates, only that process is restarted.
    Supervisor.init(children, strategy: :one_for_one)
  end
end
