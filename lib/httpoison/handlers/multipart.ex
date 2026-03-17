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
      case parse_multipart_boundary(headers) do
        {:ok, boundary} ->
          case :hackney_multipart.decode_form(boundary, body) do
            {:ok, []} -> body
            {:ok, parsed} -> parsed
            {_, _} -> body
          end

        :error ->
          body
      end
    rescue
      _ in ErlangError -> body
    end
  end

  defp parse_multipart_boundary(headers) when is_list(headers) do
    with value when not is_nil(value) <- get_header_value(headers, "content-type"),
         {:ok, boundary} <- parse_boundary(to_string(value)) do
      {:ok, boundary}
    else
      _ -> :error
    end
  end

  defp parse_multipart_boundary(_headers), do: :error

  defp parse_boundary(content_type) do
    binary_content_type = to_binary(content_type)

    # Prefer hackney's parser when available, but keep a fallback for older/newer API drifts.
    case parse_boundary_with_hackney(binary_content_type) do
      {:ok, boundary} ->
        {:ok, normalize_boundary(boundary)}

      :error ->
        parse_boundary_with_regex(content_type)
    end
  end

  defp parse_boundary_with_hackney(content_type) do
    if function_exported?(:hackney_headers, :parse_content_type, 1) do
      case :hackney_headers.parse_content_type(content_type) do
        {type, _subtype, params} when type in [<<"multipart">>, "multipart"] ->
          case Enum.find_value(params, fn
                 {<<"boundary">>, boundary} -> boundary
                 _ -> nil
               end) do
            nil -> :error
            boundary -> {:ok, boundary}
          end

        _ ->
          :error
      end
    else
      :error
    end
  end

  defp parse_boundary_with_regex(content_type) do
    case Regex.run(~r/boundary=(?:"([^\"]+)"|([^;,\s]+))/i, content_type, capture: :all_but_first) do
      [value] when value != "" ->
        {:ok, normalize_boundary(value)}

      [quoted, unquoted] when quoted != "" and unquoted == "" ->
        {:ok, normalize_boundary(quoted)}

      [quoted, unquoted] when quoted == "" and unquoted != "" ->
        {:ok, normalize_boundary(unquoted)}

      _ ->
        :error
    end
  end

  defp normalize_boundary(boundary) do
    boundary
    |> to_string()
    |> String.trim()
    |> String.trim("\"")
  end

  defp get_header_value(headers, key) do
    Enum.find_value(headers, fn
      {header_key, value} ->
        if String.downcase(to_string(header_key)) == key do
          value
        end

      _ ->
        nil
    end)
  end

  defp to_binary(value) when is_binary(value), do: value
  defp to_binary(value) when is_list(value), do: List.to_string(value)
end
