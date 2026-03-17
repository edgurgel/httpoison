defmodule HTTPoison.Base do
  @moduledoc """
  Provides a default implementation for HTTPoison functions.

  This module is meant to be `use`'d in custom modules in order to wrap the
  functionalities provided by HTTPoison. For example, this is very useful to
  build API clients around HTTPoison:

      defmodule GitHub do
        use HTTPoison.Base

        @endpoint "https://api.github.com"

        def process_request_url(url) do
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
      @spec process_request_url(binary) :: binary
      def process_request_url(url)

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

  require Record
  alias HTTPoison.Request
  alias HTTPoison.Response
  alias HTTPoison.AsyncResponse
  alias HTTPoison.MaybeRedirect
  alias HTTPoison.Error

  @async_once_registry :httpoison_async_once_registry
  @async_stream_next_timeout 5_000

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
  @callback get(url, headers) :: {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}
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
    quote location: :keep do
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
      def transformer(target), do: transformer(target, nil)

      @doc false
      @spec transformer(pid, :once | nil) :: :ok
      def transformer(target, async_mode) do
        # Track the target process so we can exit when it dies
        Process.monitor(target)

        HTTPoison.Base.transformer(
          __MODULE__,
          target,
          &process_response_status_code/1,
          &process_response_headers/1,
          &process_response_chunk/1,
          async_mode
        )
      end

      @doc ~S"""
      Issues an HTTP request using an `HTTPoison.Request` struct.

      This function returns `{:ok, response}`, `{:ok, async_response}`, or `{:ok, maybe_redirect}`
      if the request is successful, `{:error, reason}` otherwise.

      ## Redirect handling

      If the option `:follow_redirect` is given, HTTP redirects are automatically follow if
      the method is set to `:get` or `:head` and the response's `status_code` is `301`, `302` or
      `307`.

      If the method is set to `:post`, then the only `status_code` that gets automatically
      followed is `303`.

      If any other method or `status_code` is returned, then this function
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

        body =
          request.body
          |> process_request_body()
          |> HTTPoison.Base.maybe_process_form()

        request = %Request{
          method: request.method,
          url: url,
          headers: process_request_headers(request.headers),
          body: body,
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

      If the method is set to `:post`, then the only `status_code` that gets automatically
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
      Issues an HTTP request an `HTTPoison.Request` struct.
      exception in case of failure.

      `request!/1` works exactly like `request/1` but it returns just the
      response in case of a successful request, raising an exception in case the
      request fails.
      """
      @spec request!(Request.t()) :: Response.t() | AsyncResponse.t() | MaybeRedirect.t()
      def request!(%Request{} = request) do
        case request(request) do
          {:ok, response} -> response
          {:error, %Error{reason: reason}} -> raise Error, reason: reason
        end
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
        case HTTPoison.Base.stream_next(id) do
          :ok -> {:ok, resp}
          err -> {:error, %Error{reason: "stream_next/1 failed", id: id}}
        end
      end

      defoverridable Module.definitions_in(__MODULE__)
    end
  end

  @doc false
  def stream_next(id) do
    case get_async_once_owner(id) do
      nil ->
        :hackney.stream_next(id)

      transformer when is_pid(transformer) ->
        if Process.alive?(transformer) do
          ref = make_ref()
          send(transformer, {:httpoison_stream_next, self(), ref, id})

          receive do
            {^ref, result} ->
              result
          after
            @async_stream_next_timeout ->
              # Stale registry entry fallback: preserve stream_next semantics instead of timing out.
              maybe_unregister_async_once_stream(id)
              :hackney.stream_next(id)
          end
        else
          maybe_unregister_async_once_stream(id)
          :hackney.stream_next(id)
        end
    end
  end

  @doc false
  def transformer(
        module,
        target,
        process_response_status_code,
        process_response_headers,
        process_response_chunk,
        async_mode
      ) do
    transformer_loop(%{
      module: module,
      target: target,
      process_response_status_code: process_response_status_code,
      process_response_headers: process_response_headers,
      process_response_chunk: process_response_chunk,
      async_mode: async_mode,
      once_credit: if(async_mode == :once, do: 1, else: 0),
      once_queue: :queue.new(),
      stream_id: nil
    })
  end

  defp transformer_loop(state) do
    target = state.target

    receive do
      {:hackney_response, id, {:status, code, _reason}} ->
        message = %HTTPoison.AsyncStatus{id: id, code: state.process_response_status_code.(code)}
        handle_async_message(state, id, message, false)

      {:hackney_response, id, {:headers, headers}} ->
        message = %HTTPoison.AsyncHeaders{
          id: id,
          headers: state.process_response_headers.(headers)
        }

        handle_async_message(state, id, message, false)

      {:hackney_response, id, :done} ->
        message = %HTTPoison.AsyncEnd{id: id}
        handle_async_message(state, id, message, true)

      {:hackney_response, id, {:error, reason}} ->
        message = %Error{id: id, reason: reason}
        handle_async_message(state, id, message, true)

      {:hackney_response, id, {redirect, to, headers}} when redirect in [:redirect, :see_other] ->
        message = %HTTPoison.AsyncRedirect{
          id: id,
          to: to,
          headers: state.process_response_headers.(headers)
        }

        handle_async_message(state, id, message, false)

      {:hackney_response, id, chunk} ->
        message = %HTTPoison.AsyncChunk{id: id, chunk: state.process_response_chunk.(chunk)}
        handle_async_message(state, id, message, false)

      {:httpoison_stream_next, from, ref, id} ->
        {result, next_state, stop?} = handle_stream_next(state, id)
        send(from, {ref, result})

        if stop? do
          :ok
        else
          transformer_loop(next_state)
        end

      # Exit if the target process dies as this will be a zombie
      {:DOWN, _ref, :process, ^target, _reason} ->
        maybe_unregister_async_once_stream(state.stream_id)
        :ok
    end
  end

  defp handle_async_message(state, id, message, terminal?) do
    state = maybe_register_async_once_stream(state, id)

    case state.async_mode do
      :once ->
        handle_async_once_message(state, id, message, terminal?)

      _ ->
        send(state.target, message)

        if terminal? do
          maybe_unregister_async_once_stream(id)
          :ok
        else
          transformer_loop(state)
        end
    end
  end

  defp handle_async_once_message(state, id, message, terminal?) do
    # Preserve HTTPoison's observable `async: :once` contract:
    # exactly one async event is delivered per `stream_next/1` credit.
    if state.once_credit > 0 and :queue.is_empty(state.once_queue) do
      send(state.target, message)
      next_state = %{state | once_credit: state.once_credit - 1}

      if terminal? do
        maybe_unregister_async_once_stream(id)
        :ok
      else
        transformer_loop(next_state)
      end
    else
      queue = :queue.in({id, message, terminal?}, state.once_queue)
      transformer_loop(%{state | once_queue: queue})
    end
  end

  defp handle_stream_next(%{async_mode: :once} = state, stream_next_id) do
    case :queue.out(state.once_queue) do
      {{:value, {id, message, terminal?}}, queue} ->
        send(state.target, message)
        next_state = %{state | once_queue: queue}

        if terminal? do
          maybe_unregister_async_once_stream(id)
          {:ok, next_state, true}
        else
          {:ok, next_state, false}
        end

      {:empty, _queue} ->
        result = :hackney.stream_next(stream_next_id)

        next_state =
          if result == :ok do
            %{state | once_credit: state.once_credit + 1}
          else
            state
          end

        {result, next_state, false}
    end
  end

  defp handle_stream_next(state, stream_next_id) do
    {:hackney.stream_next(stream_next_id), state, false}
  end

  defp maybe_register_async_once_stream(%{async_mode: :once, stream_id: nil} = state, id) do
    ensure_async_once_registry!()
    :ets.insert(@async_once_registry, {id, self()})
    %{state | stream_id: id}
  end

  defp maybe_register_async_once_stream(state, _id), do: state

  defp maybe_unregister_async_once_stream(nil), do: :ok

  defp maybe_unregister_async_once_stream(id) do
    case :ets.whereis(@async_once_registry) do
      :undefined -> :ok
      _ -> :ets.delete(@async_once_registry, id)
    end
  end

  defp get_async_once_owner(id) do
    case :ets.whereis(@async_once_registry) do
      :undefined ->
        nil

      _ ->
        case :ets.lookup(@async_once_registry, id) do
          [{^id, owner}] -> owner
          [] -> nil
        end
    end
  end

  defp ensure_async_once_registry! do
    case :ets.whereis(@async_once_registry) do
      :undefined ->
        # Best-effort creation. Multiple async streams may race on first use.
        try do
          :ets.new(@async_once_registry, [:named_table, :public, :set, read_concurrency: true])
          :ok
        catch
          :error, :badarg -> :ok
        end

      _ ->
        :ok
    end
  end

  @doc false
  defp validate_request_url(url) do
    url = to_string(url)

    %{scheme: scheme, host: host} = URI.parse(url)

    cond do
      is_nil(scheme) ->
        {:error, "Invalid URL: #{url} (missing scheme e.g. http:// or https:// or http+unix://)"}

      is_nil(host) or host == "" ->
        {:error, "Invalid URL: #{url} (missing host)"}

      true ->
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

  Record.defrecordp(
    :hackney_url_record,
    Record.extract(:hackney_url, from_lib: "hackney/include/hackney_lib.hrl")
  )

  defp build_hackney_options(module, %Request{url: url, options: options}) do
    timeout = Keyword.get(options, :timeout)
    recv_timeout = Keyword.get(options, :recv_timeout)
    stream_to = Keyword.get(options, :stream_to)
    async = Keyword.get(options, :async)

    ssl =
      if ssl_opts = Keyword.get(options, :ssl) do
        # Extract the host from the URL just like hackney does
        host = hackney_url_record(:hackney_url.parse_url(url), :host)

        merge_ssl_opts_compat(host, ssl_opts)
      else
        Keyword.get(options, :ssl_override)
      end

    follow_redirect = Keyword.get(options, :follow_redirect)
    max_redirect = Keyword.get(options, :max_redirect)
    location_trusted = Keyword.get(options, :location_trusted)

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
      if is_boolean(location_trusted) do
        [{:location_trusted, location_trusted} | hn_options]
      else
        hn_options
      end

    hn_options =
      if stream_to do
        async_option =
          case async do
            nil -> :async
            :once -> {:async, :once}
          end

        [
          async_option,
          {:stream_to, spawn_link(module, :transformer, [stream_to, async])}
          | hn_options
        ]
      else
        hn_options
      end

    hn_options
  end

  defp merge_ssl_opts_compat(host, ssl_opts) do
    if function_exported?(:hackney_connection, :merge_ssl_opts, 2) do
      apply(:hackney_connection, :merge_ssl_opts, [host, ssl_opts])
      |> normalize_ssl_ca_options()
    else
      # Hackney 3+ already merges SSL defaults internally.
      normalize_ssl_ca_options(ssl_opts)
    end
  end

  defp normalize_ssl_ca_options(ssl_opts) do
    cacertfile = Keyword.get(ssl_opts, :cacertfile)
    has_cacerts = Keyword.has_key?(ssl_opts, :cacerts)

    cond do
      is_nil(cacertfile) or has_cacerts ->
        ssl_opts

      true ->
        # OTP 25 + Hackney 3 may require in-memory certs (`:cacerts`) while callers
        # often still provide `:cacertfile`, so convert when possible.
        case certs_from_pem_file(cacertfile) do
          {:ok, certs} when certs != [] ->
            ssl_opts
            |> Keyword.delete(:cacertfile)
            |> Keyword.put(:cacerts, certs)

          _ ->
            ssl_opts
        end
    end
  end

  defp certs_from_pem_file(path) do
    with {:ok, pem} <- File.read(to_string(path)) do
      certs =
        pem
        |> :public_key.pem_decode()
        |> Enum.reduce([], fn
          {:Certificate, der, _}, acc -> [der | acc]
          _, acc -> acc
        end)
        |> Enum.reverse()

      {:ok, certs}
    end
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
    case validate_request_url(request.url) do
      :ok ->
        hn_proxy_options = build_hackney_proxy_options(request)
        hn_options = hn_proxy_options ++ build_hackney_options(module, request)
        max_length = Keyword.get(request.options, :max_body_length, :infinity)

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

          {:ok, status_code, headers, payload} ->
            case normalize_response_body(payload, max_length) do
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

          {:connect_error, {:error, reason}} ->
            {:error, %Error{reason: reason}}
        end

      {:error, reason} ->
        {:error, %Error{reason: reason}}
    end
  end

  defp normalize_response_body(payload, max_length) when is_binary(payload) do
    # Hackney 3 may return the full body inline in the request tuple.
    # Keep HTTPoison's `max_body_length` behavior consistent with client-body responses.
    {:ok, clamp_body_length(payload, max_length)}
  end

  defp normalize_response_body(payload, max_length) do
    read_response_body(payload, max_length)
  end

  defp read_response_body(client, max_length) do
    cond do
      function_exported?(:hackney, :body, 2) ->
        apply(:hackney, :body, [client, max_length])

      function_exported?(:hackney_conn, :body, 2) ->
        :hackney_conn.body(client, max_length)

      function_exported?(:hackney_conn, :body, 1) ->
        case :hackney_conn.body(client) do
          {:ok, body} -> {:ok, clamp_body_length(body, max_length)}
          other -> other
        end

      true ->
        {:error, :unsupported_response_body}
    end
  end

  defp clamp_body_length(body, :infinity), do: body

  defp clamp_body_length(body, max_length) when is_binary(body) and is_integer(max_length) do
    binary_part(body, 0, min(byte_size(body), max_length))
  end

  defp clamp_body_length(body, _max_length), do: body

  defp do_request(%Request{body: {:stream, enumerable}} = request, hn_options) do
    with {:ok, ref} <-
           :hackney.request(request.method, request.url, request.headers, :stream, hn_options) do
      failures =
        Stream.transform(enumerable, :ok, fn
          _, :error -> {:halt, :error}
          chunk, :ok when chunk in ["", <<>>] -> {[], :ok}
          bin, :ok -> {[], :hackney.send_body(ref, bin)}
          _, error -> {[error], :error}
        end)
        |> Enum.into([])

      case failures do
        [] ->
          case :hackney.finish_send_body(ref) do
            :ok -> :hackney.start_response(ref)
            error -> error
          end

        [failure] ->
          failure
      end
    end
  end

  defp do_request(request, hn_options) do
    headers = maybe_add_default_content_type(request.method, request.headers, request.body)
    :hackney.request(request.method, request.url, headers, request.body, hn_options)
  end

  defp maybe_add_default_content_type(method, headers, body)
       when method in [:post, :put, :patch] and body in ["", <<>>] do
    if has_header?(headers, "content-type") do
      headers
    else
      [{"Content-Type", "application/octet-stream"} | headers]
    end
  end

  defp maybe_add_default_content_type(_method, headers, _body), do: headers

  defp has_header?(headers, header_name) do
    Enum.any?(headers, fn
      {name, _value} -> String.downcase(to_string(name)) == header_name
      _ -> false
    end)
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
       redirect_url: get_header(headers, "Location", nil)
     }}
  end

  defp get_header(headers, key, default) do
    key = String.downcase(key)

    Enum.find_value(headers, default, fn
      {k, v} -> if String.downcase(k) == key, do: v, else: nil
      _ -> nil
    end)
  end

  def maybe_process_form({:form, body}) do
    {:form,
     Enum.flat_map(body, fn
       {k, [{_k, _v} | _rest] = v} -> flatten_nested_body(v, k)
       {k, v} when is_map(v) -> flatten_nested_body(v, k)
       {k, v} -> [{k, v}]
     end)}
  end

  def maybe_process_form(body) do
    body
  end

  defp flatten_nested_body(body, parent_key) do
    flattened_body =
      Enum.reduce(body, [], fn
        {key, nested_key_values}, acc when is_map(nested_key_values) ->
          flatten_nested_body(nested_key_values, "#{parent_key}[#{key}]") ++ acc

        {key, [{_key, _value} | _rest] = nested_key_values}, acc ->
          flatten_nested_body(nested_key_values, "#{parent_key}[#{key}]") ++ acc

        {key, value}, acc ->
          [{"#{parent_key}[#{key}]", value} | acc]
      end)

    Enum.reverse(flattened_body)
  end
end
