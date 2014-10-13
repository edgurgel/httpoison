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

  defmodule Error do
    defexception reason: nil, id: nil
    @type t :: %Error{id: reference, reason: any}

    def message(%Error{reason: reason, id: nil}), do: inspect(reason)
    def message(%Error{reason: reason, id: id}), do: "[Reference: #{id}] - #{inspect reason}"
  end

  use HTTPoison.Base
end
