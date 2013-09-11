defmodule HTTPoison.Base do
  defmacro __using__(_) do
    quote do
      def start do
        Enum.each [:ssl, :hackney], Application.Behaviour.start(&1)
      end

      def process_url(url) do
        unless url =~ %r/\Ahttps?:\/\// do
          "http://" <> url
        else
          url
        end
      end

      def process_request_body(body), do: body

      def process_response_body(body), do: body

      def process_headers(headers), do: headers

      def process_status_code(status_code), do: status_code

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
      def request(method, url, body // "", headers // [], options // []) do
        timeout = Keyword.get options, :timeout, 5000
        hn_options = Keyword.get options, :hackney, []
        body = process_request_body body

        case :hackney.request(method,
                              process_url(to_string(url)),
                              headers,
                              body,
                              hn_options) do
           {:ok, status_code, headers, client} ->
             {:ok, body, client} = :hackney.body(client)
             HTTPoison.Response[
               status_code: process_status_code(status_code),
               headers: process_headers(headers),
               body: process_response_body(body)
             ]
           {:error, reason} ->
             raise HTTPoison.HTTPError[message: to_string(reason)]
         end

        #if stream_to, do:
          #ib_options = Dict.put(ib_options, :stream_to, spawn(__MODULE__, :transformer, [stream_to]))
      end

      def get(url, headers // [], options // []),         do: request(:get, url, "", headers, options)
      def put(url, body, headers // [], options // []),   do: request(:put, url, body, headers, options)
      def head(url, headers // [], options // []),        do: request(:head, url, "", headers, options)
      def post(url, body, headers // [], options // []),  do: request(:post, url, body, headers, options)
      def patch(url, body, headers // [], options // []), do: request(:patch, url, body, headers, options)
      def delete(url, headers // [], options // []),      do: request(:delete, url, "", headers, options)
      def options(url, headers // [], options // []),     do: request(:options, url, "", headers, options)

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
  defrecord AsyncHeaders, id: nil, status_code: nil, headers: []
  defrecord AsyncChunk, id: nil, chunk: nil
  defrecord AsyncEnd, id: nil

  defexception HTTPError, message: nil

  use HTTPoison.Base
end
