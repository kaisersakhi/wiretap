defmodule Wiretap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Define the list of child processes to be supervised.
    # If a child process crashes, the Supervisor will restart it according to the strategy.
    children = [
      # Start the Wiretap.Supervisor
      # This is the top-level supervisor for our specific business logic.
      Wiretap.Supervisor
    ]

    # :one_for_one strategy means if a child process terminates, only that process is restarted.
    opts = [strategy: :one_for_one, name: Wiretap.AppSupervisor]
    Supervisor.start_link(children, opts)
  end
end
