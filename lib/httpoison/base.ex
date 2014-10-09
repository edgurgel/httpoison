defmodule HTTPoison.Base do
  defmacro __using__(_) do
    quote do
      @type headers :: map | [{binary, binary}]

      @doc """
      Start httpoison and dependencies.
      """
      def start do
        :application.ensure_all_started(:httpoison)
      end

      defp process_url(url) do
        case String.downcase(url) do
          <<"http://"::utf8, _::binary>> -> url
          <<"https://"::utf8, _::binary>> -> url
          _ -> "http://" <> url
        end
      end

      defp process_request_body(body), do: body

      defp process_response_body(body), do: body

      defp process_request_headers(headers) when is_map(headers) do
        Enum.into(headers, [])
      end
      defp process_request_headers(headers), do: headers

      defp process_response_chunk(chunk), do: chunk

      defp process_headers(headers), do: Enum.into(headers, %{})

      defp process_status_code(status_code), do: status_code

      @spec transformer(pid) :: :ok
      def transformer(target) do
        receive do
          {:hackney_response, id, {:status, code, _reason}} ->
            send target, %HTTPoison.AsyncStatus{id: id, code: process_status_code(code)}
            transformer(target)
          {:hackney_response, id, {:headers, headers}} ->
            send target, %HTTPoison.AsyncHeaders{id: id, headers: process_headers(headers)}
            transformer(target)
          {:hackney_response, id, :done} ->
            send target, %HTTPoison.AsyncEnd{id: id}
          {:hackney_response, id, chunk} ->
            send target, %HTTPoison.AsyncChunk{id: id, chunk: process_response_chunk(chunk)}
            transformer(target)
        end
      end

      @doc """
      Sends an HTTP request.
      Args:
        * method - HTTP method, atom (:get, :head, :post, :put, :delete, etc.)
        * url - URL, binary string or char list
        * body - request body, binary string or char list
        * headers - HTTP headers, orddict (eg. [{:Accept, "application/json"}])
        * options - orddict of options
      Options:
        * timeout - timeout in ms, integer
      Returns HTTPoison.Response if successful.
      Raises  HTTPoison.HTTPError if failed.
      """
      @spec request(atom, binary, binary, headers, [{atom, any}]) :: HTTPoison.Response.t | HTTPoison.AsyncResponse.t
      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        timeout = Keyword.get options, :timeout, 5000
        stream_to = Keyword.get options, :stream_to
        hn_options = [connect_timeout: timeout] ++ Keyword.get options, :hackney, []
        body = process_request_body body

        if stream_to do
          hn_options = [:async, {:stream_to, spawn(__MODULE__, :transformer, [stream_to])}] ++ hn_options
        end

        case :hackney.request(method,
                              process_url(to_string(url)),
                              process_request_headers(headers),
                              body,
                              hn_options) do
          {:ok, status_code, headers, client} when status_code in [204, 304] ->
            response(status_code, headers, "")
          {:ok, status_code, headers} ->
            response(status_code, headers, "")
          {:ok, status_code, headers, client} ->
            case :hackney.body(client) do
              {:ok, body} -> response(status_code, headers, body)
              _ -> raise HTTPoison.HTTPError, message: "Failed to fetch the body"
            end
          {:ok, id} ->
            %HTTPoison.AsyncResponse { id: id }
          {:error, reason} ->
            raise HTTPoison.HTTPError, message: inspect(reason)
         end
      end

      defp response(status_code, headers, body) do
        %HTTPoison.Response {
          status_code: process_status_code(status_code),
          headers: process_headers(headers),
          body: process_response_body(body)
        }
      end

      @spec get(binary, headers, [{atom, any}]) :: HTTPoison.Response.t | HTTPoison.AsyncResponse.t
      def get(url, headers \\ [], options \\ []),         do: request(:get, url, "", headers, options)

      @spec put(binary, binary, headers, [{atom, any}]) :: HTTPoison.Response.t | HTTPoison.AsyncResponse.t
      def put(url, body, headers \\ [], options \\ []),   do: request(:put, url, body, headers, options)

      @spec head(binary, headers, [{atom, any}]) :: HTTPoison.Response.t | HTTPoison.AsyncResponse.t
      def head(url, headers \\ [], options \\ []),        do: request(:head, url, "", headers, options)

      @spec post(binary, binary, headers, [{atom, any}]) :: HTTPoison.Response.t | HTTPoison.AsyncResponse.t
      def post(url, body, headers \\ [], options \\ []),  do: request(:post, url, body, headers, options)

      @spec patch(binary, binary, headers, [{atom, any}]) :: HTTPoison.Response.t | HTTPoison.AsyncResponse.t
      def patch(url, body, headers \\ [], options \\ []), do: request(:patch, url, body, headers, options)

      @spec delete(binary, headers, [{atom, any}]) :: HTTPoison.Response.t | HTTPoison.AsyncResponse.t
      def delete(url, headers \\ [], options \\ []),      do: request(:delete, url, "", headers, options)

      @spec options(binary, headers, [{atom, any}]) :: HTTPoison.Response.t | HTTPoison.AsyncResponse.t
      def options(url, headers \\ [], options \\ []),     do: request(:options, url, "", headers, options)

      defoverridable Module.definitions_in(__MODULE__)
    end
  end
end
