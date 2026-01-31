defmodule Wiretap.Request do
  @methods ~w(get post put patch delete head options)

  defstruct [:method, :target, :path, :query, :headers, :body, :version]

  def new!(attrs) do
    method = Keyword.fetch!(attrs, :method)

    unless method in @methods do
      raise ArgumentError, "invalid HTTP method: #{inspect(method)}"
    end

    struct!(__MODULE__, attrs)
  end
end
