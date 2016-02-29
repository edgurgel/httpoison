defmodule HTTPoison.Base do
  @moduledoc """
  Provides a default implementation for HTTPoison functions.

  This module is meant to be `use`'d in custom modules in order to wrap the
  functionalities provided by HTTPoison. For example, this is very useful to
  build API clients around HTTPoison:

      defmodule GitHub do
        use HTTPoison.Base

        @endpoint "https://api.github.com"

        defp process_url(url) do
          @endpoint <> url
        end
      end

  The example above shows how the `GitHub` module can wrap HTTPoison
  functionalities to work with the GitHub API in particular; this way, for
  example, all requests done through the `GitHub` module will be done to the
  GitHub API:

      GitHub.get("/users/octocat/orgs")
      #=> will issue a GET request at https://api.github.com/users/octocat/orgs

  ## Overriding functions

  `HTTPoison.Base` defines the following list of functions, all of which can be
  overridden (by redefining them). The following list also shows the typespecs
  for these functions and a short description.

      # Called in order to process the url passed to any request method before
      # actually issuing the request.
      @spec process_url(binary) :: binary
      defp process_url(url)

      # Called to arbitrarly process the request body before sending it with the
      # request.
      @spec process_request_body(term) :: binary
      defp process_request_body(body)

      # Called to arbitrarly process the request headers before sending them
      # with the request.
      @spec process_request_headers(term) :: [{binary, term}]
      defp process_request_headers(headers)

      # Called before returning the response body returned by a request to the
      # caller.
      @spec process_response_body(binary) :: term
      defp process_response_body(body)

      # Used when an async request is made; it's called on each chunk that gets
      # streamed before returning it to the streaming destination.
      @spec process_response_chunk(binary) :: term
      defp process_response_chunk(chunk)

      # Called to process the response headers before returing them to the
      # caller.
      @spec process_headers([{binary, term}]) :: term
      defp process_headers(headers)

      # Used to arbitrarly process the status code of a response before
      # returning it to the caller.
      @spec process_status_code(integer) :: term
      defp process_status_code(status_code)

  """

  alias HTTPoison.Response
  alias HTTPoison.AsyncResponse
  alias HTTPoison.Error

  defmacro __using__(_) do
    quote do
      @type headers :: [{binary, binary}] | %{binary => binary}
      @type body :: binary | {:form, [{atom, any}]} | {:file, binary}

      @doc """
      Starts HTTPoison and its dependencies.
      """
      def start, do: :application.ensure_all_started(:httpoison)

      defp process_url(url) do
        HTTPoison.Base.default_process_url(url)
      end

      defp process_request_body(body), do: body

      defp process_response_body(body), do: body

      defp process_request_headers(headers) when is_map(headers) do
        Enum.into(headers, [])
      end
      defp process_request_headers(headers), do: headers

      defp process_response_chunk(chunk), do: chunk

      defp process_headers(headers), do: headers

      defp process_status_code(status_code), do: status_code

      @doc false
      @spec transformer(pid) :: :ok
      def transformer(target) do
        HTTPoison.Base.transformer(__MODULE__, target, &process_status_code/1, &process_headers/1, &process_response_chunk/1)
      end

      @doc ~S"""
      Issues an HTTP request with the given method to the given url.

      This function is usually used indirectly by `get/3`, `post/4`, `put/4`, etc

      Args:
        * `method` - HTTP method as an atom (`:get`, `:head`, `:post`, `:put`,
          `:delete`, etc.)
        * `url` - target url as a binary string or char list
        * `body` - request body. See more below
        * `headers` - HTTP headers as an orddict (e.g., `[{"Accept", "application/json"}]`)
        * `options` - Keyword list of options

      Body:
        * binary, char list or an iolist
        * `{:form, [{K, V}, ...]}` - send a form url encoded
        * `{:file, "/path/to/file"}` - send a file

      Options:
        * `:timeout` - timeout to establish a connection, in milliseconds. Default is 8000
        * `:recv_timeout` - timeout used when receiving a connection. Default is 5000
        * `:stream_to` - a PID to stream the response to
        * `:proxy` - a proxy to be used for the request; it can be a regular url
          or a `{Host, Proxy}` tuple
        * `:proxy_auth` - proxy authentication `{User, Password}` tuple
        * `:ssl` - SSL options supported by the `ssl` erlang module
        * `:follow_redirect` - a boolean that causes redirects to be followed
        * `:max_redirect` - an integer denoting the maximum number of redirects to follow
        * `:params` - an enumerable consisting of two-item tuples that will be appended to the url as query string parameters

      Timeouts can be an integer or `:infinity`

      This function returns `{:ok, response}` or `{:ok, async_response}` if the
      request is successful, `{:error, reason}` otherwise.

      ## Examples

          request(:post, "https://my.website.com", "{\"foo\": 3}", [{"Accept", "application/json"}])

      """
      @spec request(atom, binary, body, headers, Keyword.t) :: {:ok, Response.t | AsyncResponse.t}
        | {:error, Error.t}
      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        if Keyword.has_key?(options, :params) do
          url = url <> "?" <> URI.encode_query(options[:params])
        end
        url = process_url(to_string(url))
        body = process_request_body(body)
        headers = process_request_headers(headers)
        HTTPoison.Base.request(__MODULE__, method, url, body, headers, options, &process_status_code/1, &process_headers/1, &process_response_body/1)
      end

      @doc """
      Issues an HTTP request with the given method to the given url, raising an
      exception in case of failure.

      `request!/5` works exactly like `request/5` but it returns just the
      response in case of a successful request, raising an exception in case the
      request fails.
      """
      @spec request!(atom, binary, body, headers, Keyword.t) :: Response.t
      def request!(method, url, body \\ "", headers \\ [], options \\ []) do
        case request(method, url, body, headers, options) do
          {:ok, response} -> response
          {:error, error} -> raise error
        end
      end

      @doc """
      Issues a GET request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec get(binary, headers, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def get(url, headers \\ [], options \\ []),          do: request(:get, url, "", headers, options)

      @doc """
      Issues a GET request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec get!(binary, headers, Keyword.t) :: Response.t | AsyncResponse.t
      def get!(url, headers \\ [], options \\ []),         do: request!(:get, url, "", headers, options)

      @doc """
      Issues a PUT request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec put(binary, body, headers, Keyword.t) :: {:ok, Response.t | AsyncResponse.t } | {:error, Error.t}
      def put(url, body, headers \\ [], options \\ []),    do: request(:put, url, body, headers, options)

      @doc """
      Issues a PUT request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec put!(binary, body, headers, Keyword.t) :: Response.t | AsyncResponse.t
      def put!(url, body, headers \\ [], options \\ []),   do: request!(:put, url, body, headers, options)

      @doc """
      Issues a HEAD request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec head(binary, headers, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def head(url, headers \\ [], options \\ []),         do: request(:head, url, "", headers, options)

      @doc """
      Issues a HEAD request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec head!(binary, headers, Keyword.t) :: Response.t | AsyncResponse.t
      def head!(url, headers \\ [], options \\ []),        do: request!(:head, url, "", headers, options)

      @doc """
      Issues a POST request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec post(binary, body, headers, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def post(url, body, headers \\ [], options \\ []),   do: request(:post, url, body, headers, options)

      @doc """
      Issues a POST request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec post!(binary, body, headers, Keyword.t) :: Response.t | AsyncResponse.t
      def post!(url, body, headers \\ [], options \\ []),  do: request!(:post, url, body, headers, options)

      @doc """
      Issues a PATCH request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec patch(binary, body, headers, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def patch(url, body, headers \\ [], options \\ []),  do: request(:patch, url, body, headers, options)

      @doc """
      Issues a PATCH request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec patch!(binary, body, headers, Keyword.t) :: Response.t | AsyncResponse.t
      def patch!(url, body, headers \\ [], options \\ []), do: request!(:patch, url, body, headers, options)

      @doc """
      Issues a DELETE request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec delete(binary, headers, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def delete(url, headers \\ [], options \\ []),       do: request(:delete, url, "", headers, options)

      @doc """
      Issues a DELETE request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec delete!(binary, headers, Keyword.t) :: Response.t | AsyncResponse.t
      def delete!(url, headers \\ [], options \\ []),      do: request!(:delete, url, "", headers, options)

      @doc """
      Issues an OPTIONS request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec options(binary, headers, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, Error.t}
      def options(url, headers \\ [], options \\ []),      do: request(:options, url, "", headers, options)

      @doc """
      Issues a OPTIONS request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec options!(binary, headers, Keyword.t) :: Response.t | AsyncResponse.t
      def options!(url, headers \\ [], options \\ []),     do: request!(:options, url, "", headers, options)

      defoverridable Module.definitions_in(__MODULE__)
    end
  end

  @doc false
  def transformer(module, target, process_status_code, process_headers, process_response_chunk) do
    receive do
      {:hackney_response, id, {:status, code, _reason}} ->
        send target, %HTTPoison.AsyncStatus{id: id, code: process_status_code.(code)}
        transformer(module, target, process_status_code, process_headers, process_response_chunk)
      {:hackney_response, id, {:headers, headers}} ->
        send target, %HTTPoison.AsyncHeaders{id: id, headers: process_headers.(headers)}
        transformer(module, target, process_status_code, process_headers, process_response_chunk)
      {:hackney_response, id, :done} ->
        send target, %HTTPoison.AsyncEnd{id: id}
      {:hackney_response, id, {:error, reason}} ->
        send target, %Error{id: id, reason: reason}
      {:hackney_response, id, {redirect, to, headers}} when redirect in [:redirect, :see_other] ->
        send target, %HTTPoison.AsyncRedirect{id: id, to: to, headers: process_headers.(headers)}
      {:hackney_response, id, chunk} ->
        send target, %HTTPoison.AsyncChunk{id: id, chunk: process_response_chunk.(chunk)}
        transformer(module, target, process_status_code, process_headers, process_response_chunk)
    end
  end

  @doc false
  def default_process_url(url) do
    case url |> String.slice(0, 8) |> String.downcase do
      "http://" <> _ -> url
      "https://" <> _ -> url
      _ -> "http://" <> url
    end
  end

  defp build_hackney_options(module, options) do
    timeout = Keyword.get options, :timeout
    recv_timeout = Keyword.get options, :recv_timeout
    stream_to = Keyword.get options, :stream_to
    proxy = Keyword.get options, :proxy
    proxy_auth = Keyword.get options, :proxy_auth
    ssl = Keyword.get options, :ssl
    follow_redirect = Keyword.get options, :follow_redirect
    max_redirect = Keyword.get options, :max_redirect

    hn_options = Keyword.get options, :hackney, []

    if timeout, do: hn_options = [{:connect_timeout, timeout} | hn_options]
    if recv_timeout, do: hn_options = [{:recv_timeout, recv_timeout} | hn_options]
    if proxy, do: hn_options = [{:proxy, proxy} | hn_options]
    if proxy_auth, do: hn_options = [{:proxy_auth, proxy_auth} | hn_options]
    if ssl, do: hn_options = [{:ssl_options, ssl} | hn_options]
    if follow_redirect, do: hn_options = [{:follow_redirect, follow_redirect} | hn_options]
    if max_redirect, do: hn_options = [{:max_redirect, max_redirect} | hn_options]

    if stream_to do
      hn_options = [:async, {:stream_to, spawn(module, :transformer, [stream_to])} | hn_options]
    end

    hn_options
  end

  @doc false
  def request(module, method, request_url, request_body, request_headers, options, process_status_code, process_headers, process_response_body) do
    hn_options = build_hackney_options(module, options)

    case :hackney.request(method, request_url, request_headers,
                          request_body, hn_options) do
      {:ok, status_code, headers} -> response(process_status_code, process_headers, process_response_body, status_code, headers, "")
      {:ok, status_code, headers, client} ->
        case :hackney.body(client) do
          {:ok, body} -> response(process_status_code, process_headers, process_response_body, status_code, headers, body)
          {:error, reason} -> {:error, %Error{reason: reason} }
        end
      {:ok, id} -> { :ok, %HTTPoison.AsyncResponse{ id: id } }
      {:error, reason} -> {:error, %Error{reason: reason}}
     end
  end

  defp response(process_status_code, process_headers, process_response_body, status_code, headers, body) do
    {:ok, %Response {
      status_code: process_status_code.(status_code),
      headers: process_headers.(headers),
      body: process_response_body.(body)
    } }
  end
end
