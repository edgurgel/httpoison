defmodule HTTPoison.Response do
  defstruct status_code: nil, body: nil, headers: [], request_url: nil
  @type t :: %__MODULE__{status_code: integer, body: term, headers: list}
end

defmodule HTTPoison.AsyncResponse do
  defstruct id: nil
  @type t :: %__MODULE__{id: reference}
end

defmodule HTTPoison.AsyncStatus do
  defstruct id: nil, code: nil
  @type t :: %__MODULE__{id: reference, code: integer}
end

defmodule HTTPoison.AsyncHeaders do
  defstruct id: nil, headers: []
  @type t :: %__MODULE__{id: reference, headers: list}
end

defmodule HTTPoison.AsyncChunk do
  defstruct id: nil, chunk: nil
  @type t :: %__MODULE__{id: reference, chunk: binary}
end

defmodule HTTPoison.AsyncRedirect do
  defstruct id: nil, to: nil, headers: []
  @type t :: %__MODULE__{id: reference, to: String.t, headers: list}
end

defmodule HTTPoison.AsyncEnd do
  defstruct id: nil
  @type t :: %__MODULE__{id: reference}
end

defmodule HTTPoison.Error do
  defexception reason: nil, id: nil
  @type t :: %__MODULE__{id: reference | nil, reason: any}

  def message(%__MODULE__{reason: reason, id: nil}), do: inspect(reason)
  def message(%__MODULE__{reason: reason, id: id}), do: "[Reference: #{id}] - #{inspect reason}"
end

defmodule HTTPoison do
  @moduledoc """
  The HTTP client for Elixir.

  The `HTTPoison` module can be used to issue HTTP requests and parse HTTP responses to arbitrary urls.

      iex> HTTPoison.get!("https://api.github.com")
      %HTTPoison.Response{status_code: 200,
                          headers: [{"content-type", "application/json"}],
                          body: "{...}"}

  It's very common to use HTTPoison in order to wrap APIs, which is when the
  `HTTPoison.Base` module shines. Visit the documentation for `HTTPoison.Base`
  for more information.

  Under the hood, the `HTTPoison` module just uses `HTTPoison.Base` (as
  described in the documentation for `HTTPoison.Base`) without overriding any
  default function.

  See `request/5` for more details on how to issue HTTP requests
  """

  use HTTPoison.Base
end
