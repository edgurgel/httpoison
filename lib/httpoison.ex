defmodule HTTPoison do
  @moduledoc """
  The HTTP client for Elixir.
  """

  defmodule Response do
    defstruct status_code: nil, body: nil, headers: []
  end

  defmodule AsyncResponse do
    defstruct id: nil
  end

  defmodule AsyncStatus do
    defstruct id: nil, code: nil
  end

  defmodule AsyncHeaders do
    defstruct id: nil, headers: []
  end

  defmodule AsyncChunk do
    defstruct id: nil, chunk: nil
  end

  defmodule AsyncEnd do
    defstruct id: nil
  end

  defmodule HTTPError do
    defexception message: nil
  end

  use HTTPoison.Base
end
