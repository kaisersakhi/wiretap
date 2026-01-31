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
      {Wiretap.TCPListener, 4010}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
