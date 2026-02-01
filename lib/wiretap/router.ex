defmodule Wiretap.Router do
  alias Wiretap.{Request, Response}
  defstruct routes: []

  def new do
    %__MODULE__{}
  end

  def get(%Wiretap.Router{routes: routes} = router, path, handler_fn) do
    new_route = {:get, path, handler_fn}
    %{router | routes: routes ++ [new_route]}
  end

  def dispatch(%Wiretap.Request{method: method, path: path} = request) do
    # TODO: Implement router
    routes = []
    case Enum.find(routes, fn {m, p, _} -> m == method and p == path end) do
      {_, _, handler_fn} -> handler_fn.(request)

      nil ->
        %Response{}
    end
  end
end
