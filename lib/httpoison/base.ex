defmodule HTTPoison.Base do
  alias HTTPoison.Response
  alias HTTPoison.AsyncResponse
  alias HTTPoison.Error
  defmacro __using__(_) do
    quote do
      @type headers :: map | [{binary, binary}]

      @doc """
      Start httpoison and dependencies.
      """
      def start, do: :application.ensure_all_started(:httpoison)

      defp process_url(url, state \\ nil) do
        case String.downcase(url) do
          <<"http://"::utf8, _::binary>> -> url
          <<"https://"::utf8, _::binary>> -> url
          _ -> "http://" <> url
        end
      end
      defp process_request_headers(headers, state \\ nil)

      defp process_request_headers(headers, state) when is_map(headers) do
        Enum.into(headers, [])
      end
      defp process_request_headers(headers, state), do: headers

      defp process_request_body(body, state \\ nil), do: body

      defp process_status_code(status_code, state \\ nil), do: status_code

      defp process_headers(headers, state \\ nil), do: Enum.into(headers, %{})

      defp process_response_body(body, state \\ nil), do: body

      defp process_response_chunk(chunk, state \\ nil), do: chunk

      @doc false
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
          {:hackney_response, id, {:error, reason}} ->
            send target, %HTTPoison.Error{id: id, reason: reason}
          {:hackney_response, id, chunk} ->
            send target, %HTTPoison.AsyncChunk{id: id, chunk: process_response_chunk(chunk)}
            transformer(target)
        end
      end

      defp prepare_request(url, headers, body, :undefined) do
        {process_url(to_string(url)),
         process_request_headers(headers),
         process_request_body(body), :undefined}
      end

      defp prepare_request(url, headers, body, state) do
        {request_url, state}     = process_url(to_string(url), state)
        {request_headers, state} = process_request_headers(headers, state)
        {request_body, state}    = process_request_body(body, state)

        {request_url, request_headers, request_body, state}
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
        * stream_to - process id to stream the response
        * state - state to be passed through process_ functions

      Returns {:ok, Response} or {:ok, AsyncResponse} if successful.
      {:error, Error} otherwise.
      """
      @spec request(atom, binary, binary, headers, [{atom, any}]) :: {:ok, Response.t | AsyncResponse.t}
        | {:error, Error.t}
      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        timeout = Keyword.get options, :timeout, 5000
        stream_to = Keyword.get options, :stream_to
        state = Keyword.get options, :state, :undefined
        hn_options = [connect_timeout: timeout] ++ Keyword.get options, :hackney, []

        if stream_to do
          hn_options = [:async, {:stream_to, spawn(__MODULE__, :transformer, [stream_to])}] ++ hn_options
        end

        {request_url, request_headers, request_body, state} = prepare_request(url, headers, body, state)

        case :hackney.request(method, request_url, request_headers,
                              request_body, hn_options) do
          {:ok, status_code, headers, client} when status_code in [204, 304] ->
            response(status_code, headers, "", state)
          {:ok, status_code, headers} -> response(status_code, headers, "", state)
          {:ok, status_code, headers, client} ->
            case :hackney.body(client) do
              {:ok, body} -> response(status_code, headers, body, state)
              {:error, reason} -> {:error, %Error{reason: reason} }
            end
          {:ok, id} -> { :ok, %AsyncResponse { id: id } }
          {:error, reason} -> {:error, %Error{reason: reason}}
         end
      end

      @spec request!(atom, binary, binary, headers, [{atom, any}]) :: Response.t
      def request!(method, url, body \\ "", headers \\ [], options \\ []) do
        case request(method, url, body, headers, options) do
          {:ok, response} -> response
          {:error, error} -> raise error
        end
      end

      defp response(status_code, headers, body, :undefined) do
        {:ok, %Response {
          status_code: process_status_code(status_code),
          headers: process_headers(headers),
          body: process_response_body(body)
        } }
      end

      defp response(status_code, headers, body, state) do
        {status_code, state} = process_status_code(status_code, state)
        {headers, state}     = process_headers(headers, state)
        {body, state}        = process_response_body(body, state)

        {:ok, %Response { status_code: status_code, headers: headers,
                          body: body, state: state } }
      end

      @spec get(binary, headers, [{atom, any}]) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def get(url, headers \\ [], options \\ []),          do: request(:get, url, "", headers, options)

      @spec get!(binary, headers, [{atom, any}]) :: Response.t | AsyncResponse.t
      def get!(url, headers \\ [], options \\ []),         do: request!(:get, url, "", headers, options)

      @spec put(binary, binary, headers, [{atom, any}]) :: {:ok, Response.t | AsyncResponse.t } | {:error, Error.t}
      def put(url, body, headers \\ [], options \\ []),    do: request(:put, url, body, headers, options)

      @spec put!(binary, binary, headers, [{atom, any}]) :: Response.t | AsyncResponse.t
      def put!(url, body, headers \\ [], options \\ []),   do: request!(:put, url, body, headers, options)

      @spec head(binary, headers, [{atom, any}]) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def head(url, headers \\ [], options \\ []),         do: request(:head, url, "", headers, options)

      @spec head!(binary, headers, [{atom, any}]) :: Response.t | AsyncResponse.t
      def head!(url, headers \\ [], options \\ []),        do: request!(:head, url, "", headers, options)

      @spec post(binary, binary, headers, [{atom, any}]) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def post(url, body, headers \\ [], options \\ []),   do: request(:post, url, body, headers, options)

      @spec post!(binary, binary, headers, [{atom, any}]) :: Response.t | AsyncResponse.t
      def post!(url, body, headers \\ [], options \\ []),  do: request!(:post, url, body, headers, options)

      @spec patch(binary, binary, headers, [{atom, any}]) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def patch(url, body, headers \\ [], options \\ []),  do: request(:patch, url, body, headers, options)

      @spec patch!(binary, binary, headers, [{atom, any}]) :: Response.t | AsyncResponse.t
      def patch!(url, body, headers \\ [], options \\ []), do: request!(:patch, url, body, headers, options)

      @spec delete(binary, headers, [{atom, any}]) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def delete(url, headers \\ [], options \\ []),       do: request(:delete, url, "", headers, options)

      @spec delete!(binary, headers, [{atom, any}]) :: Response.t | AsyncResponse.t
      def delete!(url, headers \\ [], options \\ []),      do: request!(:delete, url, "", headers, options)

      @spec options(binary, headers, [{atom, any}]) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def options(url, headers \\ [], options \\ []),      do: request(:options, url, "", headers, options)

      @spec options!(binary, headers, [{atom, any}]) :: Response.t | AsyncResponse.t
      def options!(url, headers \\ [], options \\ []),     do: request!(:options, url, "", headers, options)

      defoverridable Module.definitions_in(__MODULE__)
    end
  end
end
