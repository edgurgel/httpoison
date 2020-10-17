defmodule HTTPoison.Base do
  @moduledoc """
  Provides a default implementation for HTTPoison functions.

  This module is meant to be `use`'d in custom modules in order to wrap the
  functionalities provided by HTTPoison. For example, this is very useful to
  build API clients around HTTPoison:

      defmodule GitHub do
        use HTTPoison.Base

        @endpoint "https://api.github.com"

        def process_url(url) do
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
      def process_url(url)

      # Called to arbitrarily process the request body before sending it with the
      # request.
      @spec process_request_body(term) :: binary
      def process_request_body(body)

      # Called to arbitrarily process the request headers before sending them
      # with the request.
      @spec process_request_headers(term) :: [{binary, term}]
      def process_request_headers(headers)

      # Called to arbitrarily process the request options before sending them
      # with the request.
      @spec process_request_options(keyword) :: keyword
      def process_request_options(options)

      # Called before returning the response body returned by a request to the
      # caller.
      @spec process_response_body(binary) :: term
      def process_response_body(body)

      # Used when an async request is made; it's called on each chunk that gets
      # streamed before returning it to the streaming destination.
      @spec process_response_chunk(binary) :: term
      def process_response_chunk(chunk)

      # Called to process the response headers before returning them to the
      # caller.
      @spec process_headers([{binary, term}]) :: term
      def process_headers(headers)

      # Used to arbitrarily process the status code of a response before
      # returning it to the caller.
      @spec process_response_status_code(integer) :: term
      def process_response_status_code(status_code)

  """

  alias HTTPoison.Request
  alias HTTPoison.Response
  alias HTTPoison.AsyncResponse
  alias HTTPoison.MaybeRedirect
  alias HTTPoison.Error

  @callback delete(url) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback delete(url, headers) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback delete(url, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}

  @callback delete!(url) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback delete!(url, headers) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback delete!(url, headers, options) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()

  @callback get(url) :: {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}
  @callback get(url, headers) :: {:ok, Response.t() | AsyncResponse.t() | {:error, Error.t()}}
  @callback get(url, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @callback get!(url) :: Response.t() | AsyncResponse.t()
  @callback get!(url, headers) :: Response.t() | AsyncResponse.t()
  @callback get!(url, headers, options) :: Response.t() | AsyncResponse.t()

  @callback head(url) :: {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}
  @callback head(url, headers) :: {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}
  @callback head(url, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @callback head!(url) :: Response.t() | AsyncResponse.t()
  @callback head!(url, headers) :: Response.t() | AsyncResponse.t()
  @callback head!(url, headers, options) :: Response.t() | AsyncResponse.t()

  @callback options(url) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback options(url, headers) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback options(url, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}

  @callback options!(url) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback options!(url, headers) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback options!(url, headers, options) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()

  @callback patch(url, body) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback patch(url, body, headers) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback patch(url, body, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}

  @callback patch!(url, body) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback patch!(url, body, headers) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback patch!(url, body, headers, options) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()

  @callback post(url, body) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback post(url, body, headers) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback post(url, body, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}

  @callback post!(url, body) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback post!(url, body, headers) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback post!(url, body, headers, options) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()

  # deprecated: Use process_request_headers/1 instead
  @callback process_headers(list) :: term

  @callback process_request_body(body) :: body

  @callback process_request_headers(headers) :: headers

  @callback process_request_options(options) :: options

  @callback process_request_url(url) :: url

  @callback process_request_params(params) :: params

  @callback process_response(response) :: term

  @callback process_response_body(binary) :: term

  @callback process_response_chunk(binary) :: term

  @callback process_response_headers(list) :: term

  @callback process_response_status_code(integer) :: term

  # deprecated: Use process_response_status_code/1 instead
  @callback process_status_code(integer) :: term

  # deprecated: Use process_request_url/1 instead
  @callback process_url(url) :: url

  @callback put(url) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback put(url, body) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback put(url, body, headers) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback put(url, body, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}

  @callback put!(url) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback put!(url, body) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback put!(url, body, headers) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback put!(url, body, headers, options) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()

  @callback request(Request.t()) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback request(method, url) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback request(method, url, body) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback request(method, url, body, headers) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  @callback request(method, url, body, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}

  @callback request!(method, url) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback request!(method, url, body) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback request!(method, url, body, headers) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()
  @callback request!(method, url, body, headers, options) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()

  @callback start() :: {:ok, [atom]} | {:error, term}

  @callback stream_next(AsyncResponse.t()) :: {:ok, AsyncResponse.t()} | {:error, Error.t()}

  @type response :: Response.t()
  @type request :: Request.t()
  @type method :: Request.method()
  @type url :: Request.url()
  @type headers :: Request.headers()
  @type body :: Request.body()
  @type options :: Request.options()
  @type params :: Request.params()

  defmacro __using__(_) do
    quote do
      @behaviour HTTPoison.Base

      @type request :: HTTPoison.Base.request()
      @type method :: HTTPoison.Base.method()
      @type url :: HTTPoison.Base.url()
      @type headers :: HTTPoison.Base.headers()
      @type body :: HTTPoison.Base.body()
      @type options :: HTTPoison.Base.options()
      @type params :: HTTPoison.Base.params()

      @doc """
      Starts HTTPoison and its dependencies.
      """
      def start, do: :application.ensure_all_started(:httpoison)

      @deprecated "Use process_request_url/1 instead"
      @spec process_url(url) :: url
      def process_url(url) do
        HTTPoison.Base.default_process_request_url(url)
      end

      @spec process_request_url(url) :: url
      def process_request_url(url), do: process_url(url)

      @spec process_request_body(body) :: body
      def process_request_body(body), do: body

      @spec process_request_headers(headers) :: headers
      def process_request_headers(headers) when is_map(headers) do
        Enum.into(headers, [])
      end

      def process_request_headers(headers), do: headers

      @spec process_request_options(options) :: options
      def process_request_options(options), do: options

      @spec process_request_params(params) :: params
      def process_request_params(params), do: params

      @spec process_response(HTTPoison.Base.response()) :: any
      def process_response(%Response{} = response), do: response

      @deprecated "Use process_response_headers/1 instead"
      @spec process_headers(list) :: any
      def process_headers(headers), do: headers

      @spec process_response_headers(list) :: any
      def process_response_headers(headers), do: process_headers(headers)

      @deprecated "Use process_response_status_code/1 instead"
      @spec process_status_code(integer) :: any
      def process_status_code(status_code), do: status_code

      @spec process_response_status_code(integer) :: any
      def process_response_status_code(status_code), do: process_status_code(status_code)

      @spec process_response_body(binary) :: any
      def process_response_body(body), do: body

      @spec process_response_chunk(binary) :: any
      def process_response_chunk(chunk), do: chunk

      @doc false
      @spec transformer(pid) :: :ok
      def transformer(target) do
        HTTPoison.Base.transformer(
          __MODULE__,
          target,
          &process_response_status_code/1,
          &process_response_headers/1,
          &process_response_chunk/1
        )
      end

      @doc ~S"""
      Issues an HTTP request using a `Request` struct.

      This function returns `{:ok, response}`, `{:ok, async_response}`, or `{:ok, maybe_redirect}`
      if the request is successful, `{:error, reason}` otherwise.

      ## Redirect handling

      If the option `:follow_redirect` is given, HTTP redirects are automatically follow if
      the method is set to `:get` or `:head` and the response's `status_code` is `301`, `302` or
      `307`.

      If the method is set to `:post`, then the only `status_code` that get's automatically
      followed is `303`.

      If any other method or `status_code` is returned, then this function returns a
      returns a `{:ok, %HTTPoison.MaybeRedirect{}}` containing the `redirect_url` for you to
      re-request with the method set to `:get`.

      ## Examples

          request = %HTTPoison.Request{
            method: :post,
            url: "https://my.website.com",
            body: "{\"foo\": 3}",
            headers: [{"Accept", "application/json"}]
          }

          request(request)

      """
      @spec request(Request.t()) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
      def request(%Request{} = request) do
        options = process_request_options(request.options)

        params =
          request.params
          |> HTTPoison.Base.merge_params(options[:params])
          |> process_request_params()

        url =
          request.url
          |> to_string()
          |> process_request_url()
          |> HTTPoison.Base.build_request_url(params)

        request = %Request{
          method: request.method,
          url: url,
          headers: process_request_headers(request.headers),
          body: process_request_body(request.body),
          params: params,
          options: options
        }

        HTTPoison.Base.request(
          __MODULE__,
          request,
          &process_response_status_code/1,
          &process_response_headers/1,
          &process_response_body/1,
          &process_response/1
        )
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

      Body: see type `HTTPoison.Request`

      Options: see type `HTTPoison.Request`

      This function returns `{:ok, response}`, `{:ok, async_response}`, or `{:ok, maybe_redirect}`
      if the request is successful, `{:error, reason}` otherwise.

      ## Redirect handling

      If the option `:follow_redirect` is given, HTTP redirects are automatically follow if
      the method is set to `:get` or `:head` and the response's `status_code` is `301`, `302` or
      `307`.

      If the method is set to `:post`, then the only `status_code` that get's automatically
      followed is `303`.

      If any other method or `status_code` is returned, then this function returns a
      returns a `{:ok, %HTTPoison.MaybeRedirect{}}` containing the `redirect_url` for you to
      re-request with the method set to `:get`.

      ## Examples

          request(:post, "https://my.website.com", "{\"foo\": 3}", [{"Accept", "application/json"}])

      """
      @spec request(method, binary, any, headers, Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        request(%Request{
          method: method,
          url: url,
          headers: headers,
          body: body,
          options: options
        })
      end

      @doc """
      Issues an HTTP request with the given method to the given url, raising an
      exception in case of failure.

      `request!/5` works exactly like `request/5` but it returns just the
      response in case of a successful request, raising an exception in case the
      request fails.
      """
      @spec request!(method, binary, any, headers, Keyword.t()) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()
      def request!(method, url, body \\ "", headers \\ [], options \\ []) do
        case request(method, url, body, headers, options) do
          {:ok, response} -> response
          {:error, %Error{reason: reason}} -> raise Error, reason: reason
        end
      end

      @doc """
      Issues a GET request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec get(binary, headers, Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}
      def get(url, headers \\ [], options \\ []), do: request(:get, url, "", headers, options)

      @doc """
      Issues a GET request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec get!(binary, headers, Keyword.t()) :: Response.t() | AsyncResponse.t()
      def get!(url, headers \\ [], options \\ []), do: request!(:get, url, "", headers, options)

      @doc """
      Issues a PUT request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec put(binary, any, headers, Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
      def put(url, body \\ "", headers \\ [], options \\ []),
        do: request(:put, url, body, headers, options)

      @doc """
      Issues a PUT request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec put!(binary, any, headers, Keyword.t()) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()
      def put!(url, body \\ "", headers \\ [], options \\ []),
        do: request!(:put, url, body, headers, options)

      @doc """
      Issues a HEAD request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec head(binary, headers, Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}
      def head(url, headers \\ [], options \\ []), do: request(:head, url, "", headers, options)

      @doc """
      Issues a HEAD request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec head!(binary, headers, Keyword.t()) :: Response.t() | AsyncResponse.t()
      def head!(url, headers \\ [], options \\ []), do: request!(:head, url, "", headers, options)

      @doc """
      Issues a POST request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec post(binary, any, headers, Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
      def post(url, body, headers \\ [], options \\ []),
        do: request(:post, url, body, headers, options)

      @doc """
      Issues a POST request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec post!(binary, any, headers, Keyword.t()) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()
      def post!(url, body, headers \\ [], options \\ []),
        do: request!(:post, url, body, headers, options)

      @doc """
      Issues a PATCH request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec patch(binary, any, headers, Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
      def patch(url, body, headers \\ [], options \\ []),
        do: request(:patch, url, body, headers, options)

      @doc """
      Issues a PATCH request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec patch!(binary, any, headers, Keyword.t()) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()
      def patch!(url, body, headers \\ [], options \\ []),
        do: request!(:patch, url, body, headers, options)

      @doc """
      Issues a DELETE request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec delete(binary, headers, Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
      def delete(url, headers \\ [], options \\ []),
        do: request(:delete, url, "", headers, options)

      @doc """
      Issues a DELETE request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec delete!(binary, headers, Keyword.t()) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()
      def delete!(url, headers \\ [], options \\ []),
        do: request!(:delete, url, "", headers, options)

      @doc """
      Issues an OPTIONS request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/5` for more detailed information.
      """
      @spec options(binary, headers, Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
      def options(url, headers \\ [], options \\ []),
        do: request(:options, url, "", headers, options)

      @doc """
      Issues a OPTIONS request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/5` for more detailed information.
      """
      @spec options!(binary, headers, Keyword.t()) ::
              Response.t() | AsyncResponse.t() | MaybeRedirect.t()
      def options!(url, headers \\ [], options \\ []),
        do: request!(:options, url, "", headers, options)

      @doc """
      Requests the next message to be streamed for a given `HTTPoison.AsyncResponse`.

      See `request!/5` for more detailed information.
      """
      @spec stream_next(AsyncResponse.t()) :: {:ok, AsyncResponse.t()} | {:error, Error.t()}
      def stream_next(resp = %AsyncResponse{id: id}) do
        case :hackney.stream_next(id) do
          :ok -> {:ok, resp}
          err -> {:error, %Error{reason: "stream_next/1 failed", id: id}}
        end
      end

      defoverridable Module.definitions_in(__MODULE__)
    end
  end

  @doc false
  def transformer(
        module,
        target,
        process_response_status_code,
        process_response_headers,
        process_response_chunk
      ) do
    # Track the target process so we can exit when it dies
    Process.monitor(target)

    receive do
      {:hackney_response, id, {:status, code, _reason}} ->
        send(target, %HTTPoison.AsyncStatus{id: id, code: process_response_status_code.(code)})

        transformer(
          module,
          target,
          process_response_status_code,
          process_response_headers,
          process_response_chunk
        )

      {:hackney_response, id, {:headers, headers}} ->
        send(target, %HTTPoison.AsyncHeaders{id: id, headers: process_response_headers.(headers)})

        transformer(
          module,
          target,
          process_response_status_code,
          process_response_headers,
          process_response_chunk
        )

      {:hackney_response, id, :done} ->
        send(target, %HTTPoison.AsyncEnd{id: id})

      {:hackney_response, id, {:error, reason}} ->
        send(target, %Error{id: id, reason: reason})

      {:hackney_response, id, {redirect, to, headers}} when redirect in [:redirect, :see_other] ->
        send(target, %HTTPoison.AsyncRedirect{
          id: id,
          to: to,
          headers: process_response_headers.(headers)
        })

      {:hackney_response, id, chunk} ->
        send(target, %HTTPoison.AsyncChunk{id: id, chunk: process_response_chunk.(chunk)})

        transformer(
          module,
          target,
          process_response_status_code,
          process_response_headers,
          process_response_chunk
        )

      # Exit if the target process dies as this will be a zombie
      {:DOWN, _ref, :process, ^target, _reason} ->
        :ok
    end
  end

  @doc false
  def default_process_request_url(url) do
    case url |> String.slice(0, 12) |> String.downcase() do
      "http://" <> _ -> url
      "https://" <> _ -> url
      "http+unix://" <> _ -> url
      _ -> "http://" <> url
    end
  end

  @doc false
  def merge_params(params, nil), do: params

  def merge_params(request_params, params) when map_size(request_params) === 0, do: params

  def merge_params(request_params, options_params) do
    Map.merge(
      Enum.into(request_params, %{}),
      Enum.into(options_params, %{})
    )
  end

  @doc false
  def build_request_url(url, nil), do: url

  def build_request_url(url, params) do
    cond do
      Enum.count(params) === 0 -> url
      URI.parse(url).query -> url <> "&" <> URI.encode_query(params)
      true -> url <> "?" <> URI.encode_query(params)
    end
  end

  defp build_hackney_options(module, %Request{options: options}) do
    timeout = Keyword.get(options, :timeout)
    recv_timeout = Keyword.get(options, :recv_timeout)
    stream_to = Keyword.get(options, :stream_to)
    async = Keyword.get(options, :async)
    ssl = Keyword.get(options, :ssl)
    follow_redirect = Keyword.get(options, :follow_redirect)
    max_redirect = Keyword.get(options, :max_redirect)

    hn_options = Keyword.get(options, :hackney, [])

    hn_options = if timeout, do: [{:connect_timeout, timeout} | hn_options], else: hn_options

    hn_options =
      if recv_timeout, do: [{:recv_timeout, recv_timeout} | hn_options], else: hn_options

    hn_options = if ssl, do: [{:ssl_options, ssl} | hn_options], else: hn_options

    hn_options =
      if follow_redirect, do: [{:follow_redirect, follow_redirect} | hn_options], else: hn_options

    hn_options =
      if max_redirect, do: [{:max_redirect, max_redirect} | hn_options], else: hn_options

    hn_options =
      if stream_to do
        async_option =
          case async do
            nil -> :async
            :once -> {:async, :once}
          end

        [async_option, {:stream_to, spawn_link(module, :transformer, [stream_to])} | hn_options]
      else
        hn_options
      end

    hn_options
  end

  defp build_hackney_proxy_options(%Request{options: options, url: request_url}) do
    proxy =
      if Keyword.has_key?(options, :proxy) do
        Keyword.get(options, :proxy)
      else
        case URI.parse(request_url).scheme do
          "http" -> System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
          "https" -> System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
          _ -> nil
        end
        |> check_no_proxy(request_url)
      end

    proxy_auth = Keyword.get(options, :proxy_auth)
    socks5_user = Keyword.get(options, :socks5_user)
    socks5_pass = Keyword.get(options, :socks5_pass)

    hn_proxy_options = if proxy && proxy != "", do: [{:proxy, proxy}], else: []

    hn_proxy_options =
      if proxy_auth, do: [{:proxy_auth, proxy_auth} | hn_proxy_options], else: hn_proxy_options

    hn_proxy_options =
      if socks5_user, do: [{:socks5_user, socks5_user} | hn_proxy_options], else: hn_proxy_options

    hn_proxy_options =
      if socks5_pass, do: [{:socks5_pass, socks5_pass} | hn_proxy_options], else: hn_proxy_options

    hn_proxy_options
  end

  defp check_no_proxy(nil, _) do
    # Don't bother to check no_proxy if there's no proxy to use anyway.
    nil
  end

  defp check_no_proxy(proxy, request_url) do
    request_host = URI.parse(request_url).host

    should_bypass_proxy =
      get_no_proxy_system_env()
      |> String.split(",")
      |> Enum.any?(fn domain -> matches_no_proxy_value?(request_host, domain) end)

    if should_bypass_proxy do
      nil
    else
      proxy
    end
  end

  defp get_no_proxy_system_env() do
    System.get_env("NO_PROXY") || System.get_env("no_PROXY") || System.get_env("no_proxy") || ""
  end

  defp matches_no_proxy_value?(request_host, no_proxy_value) do
    cond do
      no_proxy_value == "" -> false
      String.starts_with?(no_proxy_value, ".") -> String.ends_with?(request_host, no_proxy_value)
      String.contains?(no_proxy_value, "*") -> matches_wildcard?(request_host, no_proxy_value)
      true -> request_host == no_proxy_value
    end
  end

  defp matches_wildcard?(request_host, wildcard_domain) do
    Regex.escape(wildcard_domain)
    |> String.replace("\\*", ".*")
    |> Regex.compile!()
    |> Regex.match?(request_host)
  end

  @doc false
  @spec request(module, request, fun, fun, fun, fun) ::
          {:ok, Response.t() | AsyncResponse.t() | MaybeRedirect.t()} | {:error, Error.t()}
  def request(
        module,
        request,
        process_response_status_code,
        process_response_headers,
        process_response_body,
        process_response
      ) do
    hn_proxy_options = build_hackney_proxy_options(request)
    hn_options = hn_proxy_options ++ build_hackney_options(module, request)

    case do_request(request, hn_options) do
      {:ok, status_code, headers} ->
        response(
          process_response_status_code,
          process_response_headers,
          process_response_body,
          process_response,
          status_code,
          headers,
          "",
          request
        )

      {:ok, status_code, headers, client} ->
        max_length = Keyword.get(request.options, :max_body_length, :infinity)

        case :hackney.body(client, max_length) do
          {:ok, body} ->
            response(
              process_response_status_code,
              process_response_headers,
              process_response_body,
              process_response,
              status_code,
              headers,
              body,
              request
            )

          {:error, reason} ->
            {:error, %Error{reason: reason}}
        end

      {:ok, {:maybe_redirect, status_code, headers, _client}} ->
        maybe_redirect(
          process_response_status_code,
          process_response_headers,
          status_code,
          headers,
          request
        )

      {:ok, id} ->
        {:ok, %HTTPoison.AsyncResponse{id: id}}

      {:error, reason} ->
        {:error, %Error{reason: reason}}
    end
  end

  defp do_request(%Request{body: {:stream, enumerable}} = request, hn_options) do
    with {:ok, ref} <-
           :hackney.request(request.method, request.url, request.headers, :stream, hn_options) do
      failures =
        Stream.transform(enumerable, :ok, fn
          _, :error -> {:halt, :error}
          bin, :ok -> {[], :hackney.send_body(ref, bin)}
          _, error -> {[error], :error}
        end)
        |> Enum.into([])

      case failures do
        [] ->
          :hackney.start_response(ref)

        [failure] ->
          failure
      end
    end
  end

  defp do_request(request, hn_options) do
    :hackney.request(request.method, request.url, request.headers, request.body, hn_options)
  end

  defp response(
         process_response_status_code,
         process_response_headers,
         process_response_body,
         process_response,
         status_code,
         headers,
         body,
         request
       ) do
    {:ok,
     %Response{
       status_code: process_response_status_code.(status_code),
       headers: process_response_headers.(headers),
       body: process_response_body.(body),
       request: request,
       request_url: request.url
     }
     |> process_response.()}
  end

  defp maybe_redirect(
         process_response_status_code,
         process_response_headers,
         status_code,
         headers,
         request
       ) do
    {:ok,
     %MaybeRedirect{
       status_code: process_response_status_code.(status_code),
       headers: process_response_headers.(headers),
       request: request,
       request_url: request.url,
       redirect_url: :proplists.get_value("Location", headers, nil)
     }}
  end
end
