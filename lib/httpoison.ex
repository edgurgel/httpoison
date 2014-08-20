defmodule HTTPoison do
  @moduledoc """
  The HTTP client for Elixir.
  """

  defmodule Response do
    defstruct status_code: nil, body: nil, headers: %{}
    @type t :: %Response{status_code: integer, body: binary, headers: map}
  end

  defmodule AsyncResponse do
    defstruct id: nil
    @type t :: %AsyncResponse{id: reference}
  end

  defmodule AsyncStatus do
    defstruct id: nil, code: nil
    @type t :: %AsyncStatus{id: reference, code: integer}
  end

  defmodule AsyncHeaders do
    defstruct id: nil, headers: %{}
    @type t :: %AsyncHeaders{id: reference, headers: map}
  end

  defmodule AsyncChunk do
    defstruct id: nil, chunk: nil
    @type t :: %AsyncChunk{id: reference, chunk: binary}
  end

  defmodule AsyncEnd do
    defstruct id: nil
    @type t :: %AsyncEnd{id: reference}
  end

  defmodule HTTPError do
    defexception message: nil
  end

  use HTTPoison.Base
end
