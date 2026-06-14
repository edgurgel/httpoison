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
      case content_type(headers) do
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

  defp content_type(headers) do
    case find_header(headers, "content-type") do
      nil -> nil
      value -> :hackney_headers.parse_content_type(to_binary(value))
    end
  end

  defp find_header(headers, key) when is_list(headers) do
    Enum.find_value(headers, fn
      {k, v} -> if String.downcase(to_string(k)) == key, do: v
      _ -> nil
    end)
  end

  defp find_header(_headers, _key), do: nil

  defp to_binary(value) when is_binary(value), do: value
  defp to_binary(value) when is_list(value), do: IO.iodata_to_binary(value)
end
