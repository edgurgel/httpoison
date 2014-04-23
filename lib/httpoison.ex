defmodule HTTPoison.Base do
  defmacro __using__(_) do
    quote do
      def start do
        Application.Behaviour.start(:httpoison)
      end

      def process_url(url) do
        case String.downcase(url) do
          <<"http://"::utf8, _::binary>> -> url
          <<"https://"::utf8, _::binary>> -> url
          _ -> "http://" <> url
        end
      end

      def process_request_body(body), do: body

      def process_response_body(body), do: body

      def process_request_headers(headers), do: headers

      def process_response_chunk(chunk), do: chunk

      def process_headers(headers), do: headers

      def process_status_code(status_code), do: status_code

      def transformer(target) do
        receive do
          {:hackney_response, id, {:status, code, _reason}} ->
            send target, HTTPoison.AsyncStatus[id: id, code: process_status_code(code)]
            transformer(target)
          {:hackney_response, id, {:headers, headers}} ->
            send target, HTTPoison.AsyncHeaders[id: id, headers: process_headers(headers)]
            transformer(target)
          {:hackney_response, id, :done} ->
            send target, HTTPoison.AsyncEnd[id: id]
          {:hackney_response, id, chunk} ->
            send target, HTTPoison.AsyncChunk[id: id, chunk: process_response_chunk(chunk)]
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
           {:ok, 204, headers, client} -> 
            make_response(204, headers)
           {:ok, status_code, headers, client} -> 
            {:ok, body} = :hackney.body(client)
            make_response(status_code, headers, body)
           {:ok, id} ->
             HTTPoison.AsyncResponse[id: id]
           {:error, reason} ->
             raise HTTPoison.HTTPError[message: to_string(reason)]
         end
      end

      def get(url, headers \\ [], options \\ []),         do: request(:get, url, "", headers, options)
      def put(url, body, headers \\ [], options \\ []),   do: request(:put, url, body, headers, options)
      def head(url, headers \\ [], options \\ []),        do: request(:head, url, "", headers, options)
      def post(url, body, headers \\ [], options \\ []),  do: request(:post, url, body, headers, options)
      def patch(url, body, headers \\ [], options \\ []), do: request(:patch, url, body, headers, options)
      def delete(url, headers \\ [], options \\ []),      do: request(:delete, url, "", headers, options)
      def options(url, headers \\ [], options \\ []),     do: request(:options, url, "", headers, options)

      defp make_response(status_code, headers, body \\ "") do
        HTTPoison.Response[
          status_code: process_status_code(status_code),
          headers: process_headers(headers),
          body: process_response_body(body)
        ]
      end

      defoverridable Module.definitions_in(__MODULE__)
    end
  end
end

defmodule HTTPoison do
  @moduledoc """
  The HTTP client for Elixir.
  """

  defrecord Response, status_code: nil, body: nil, headers: []

  defrecord AsyncResponse, id: nil
  defrecord AsyncStatus, id: nil, code: nil
  defrecord AsyncHeaders, id: nil, headers: []
  defrecord AsyncChunk, id: nil, chunk: nil
  defrecord AsyncEnd, id: nil

  defexception HTTPError, message: nil

  use HTTPoison.Base
end
