defmodule HTTPoison.Handlers.Multipart do
  @moduledoc """
  Provides a set of functions to handle multipart requests/responses

  `HTTPoison.Handlers.Multipart` defines the following list of functions:

      # Used to parse a multipart response body
      # @type body :: binary | {:form, [{atom, any}]} | {:file, binary}
      # @spec decode_body(Response.t()) :: body
      # def decode_body(response)

  """

  alias HTTPoison.Response

  @callback decode_body(Response.t()) :: body
  @type body :: binary | {:form, [{atom, any}]} | {:file, binary}

  @doc """
  Parses a multipart response body.

  It uses `:hackney_headers` to understand if the content type of the response
  is multipart, in which case it uses `:hackney_multipart` to decode the body of
  the response.

  For example, if we have the following `multipart` response body:

      --123
      Content-type: application/json
      {\"1\": \"first\"}
      --123
      Content-type: application/json
      {\"2\": \"second\"}
      --123--

  We can parse the body of the response to its various parts:

      HTTPoison.Handlers.Multipart.decode_body(response)
      #=> will decode a multipart body, e.g. yielding
      # [
      #   {[{"Content-Type", "application/json"}], "{\"1\": \"first\"}"},
      #   {[{"Content-Type", "application/json"}], "{\"2\": \"second\"}"}
      # ]

  In case the content type is not multipart, the original body is returned.
  """
  def decode_body(%Response{body: body, headers: headers}) do
    try do
      case :hackney_headers.parse("Content-Type", headers) do
        {"multipart", _, [{"boundary", boundary} | _]} ->
          case :hackney_multipart.decode_form(boundary, body) do
            {:ok, []} -> body
            {:ok, parsed} -> parsed
            {_, _} -> body
          end

        _ ->
          body
      end
    rescue
      _ in ErlangError -> body
    end
  end
end
