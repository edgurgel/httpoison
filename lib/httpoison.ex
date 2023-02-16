defmodule HTTPoison.Request do
  @moduledoc """
  `Request` properties:

    * `:method` - HTTP method as an atom (`:get`, `:head`, `:post`, `:put`,
      `:delete`, etc.)
    * `:url` - target url as a binary string or char list
    * `:body` - request body. See more below
    * `:headers` - HTTP headers as an orddict (e.g., `[{"Accept", "application/json"}]`)
    * `:options` - Keyword list of options
    * `:params` - Query parameters as a map, keyword, or orddict

  `:body`:

    * binary, char list or an iolist
    * `{:form, [{K, V}, ...]}` - send a form url encoded
    * `{:file, "/path/to/file"}` - send a file
    * `{:stream, enumerable}` - lazily send a stream of binaries/charlists

  `:options`:

    * `:timeout` - timeout for establishing a TCP or SSL connection, in milliseconds. Default is 8000
    * `:recv_timeout` - timeout for receiving an HTTP response from the socket. Default is 5000
    * `:stream_to` - a PID to stream the response to
    * `:async` - if given `:once`, will only stream one message at a time, requires call to `stream_next`
    * `:proxy` - a proxy to be used for the request; it can be a regular url
      or a `{Host, Port}` tuple, or a `{:socks5, ProxyHost, ProxyPort}` tuple
    * `:proxy_auth` - proxy authentication `{User, Password}` tuple
    * `:socks5_user`- socks5 username
    * `:socks5_pass`- socks5 password
    * `:ssl` - SSL options supported by the `ssl` erlang module. SSL defaults will be used where options
               are not specified.
    * `:ssl_override` - if `:ssl` is specified, this option is ignored, otherwise it can be used to
              completely override SSL settings.
    * `:follow_redirect` - a boolean that causes redirects to be followed, can cause a request to return
      a `MaybeRedirect` struct. See: HTTPoison.MaybeRedirect
    * `:max_redirect` - an integer denoting the maximum number of redirects to follow. Default is 5
    * `:params` - an enumerable consisting of two-item tuples that will be appended to the url as query string parameters
    * `:max_body_length` - a non-negative integer denoting the max response body length. See :hackney.body/2

    Timeouts can be an integer or `:infinity`
  """
  @enforce_keys [:url]
  defstruct method: :get, url: nil, headers: [], body: "", params: %{}, options: []

  @type method :: :get | :post | :put | :patch | :delete | :options | :head
  @type headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary} | any
  @type url :: binary | any
  @type body :: binary | charlist | iodata | {:form, [{atom, any}]} | {:file, binary} | any
  @type params :: map | keyword | [{binary, binary}] | any
  @type options :: keyword | any

  @type t :: %__MODULE__{
          method: method,
          url: binary,
          headers: headers,
          body: body,
          params: params,
          options: options
        }

  @doc """
  Returns an equivalent `curl` command for the given request.

  ## Examples
      iex> request = %HTTPoison.Request{url: "https://api.github.com", method: :get, headers: [{"Content-Type", "application/json"}]}
      iex> HTTPoison.Request.to_curl(request)
      "curl -X GET -H 'Content-Type: application/json' https://api.github.com ;"

      iex> request = HTTPoison.get!("https://api.github.com", [{"Content-Type", "application/json"}]).request
      iex> HTTPoison.Request.to_curl(request)
      "curl -X GET -H 'Content-Type: application/json' https://api.github.com ;"
  """
  @spec to_curl(t()) :: {:ok, binary()} | {:error, atom()}
  def to_curl(request = %__MODULE__{}) do
    options =
      Enum.reduce(request.options, [], fn
        {:timeout, timeout}, acc ->
          ["--connect-timeout #{Float.round(timeout / 1000, 3)}" | acc]

        {:recv_timeout, timeout}, acc ->
          ["--max-time #{Float.round(timeout / 1000, 3)}" | acc]

        {:proxy, {:socks5, host, port}}, acc ->
          proxy_auth =
            if request.options[:socks5_user] do
              user = request.options[:socks5_user]
              pass = request.options[:socks5_pass]
              " --proxy-basic --proxy-user #{user}:#{pass}"
            end

          ["--socks5 #{host}:#{port}#{proxy_auth}" | acc]

        {:proxy, {host, port}}, acc ->
          ["--proxy #{host}:#{port}" | acc]

        {:proxy_auth, {user, pass}}, acc ->
          ["--proxy-user #{user}:#{pass}" | acc]

        {:ssl, ssl_opts}, acc ->
          ssl_opts =
            Enum.reduce(ssl_opts, [], fn
              {:keyfile, keyfile}, acc -> ["--key #{keyfile}" | acc]
              {:certfile, certfile}, acc -> ["--cert #{certfile}" | acc]
              {:cacertfile, cacertfile}, acc -> ["--cacert #{cacertfile}" | acc]
            end)
            |> Enum.join(" ")

          [ssl_opts | acc]

        {:follow_redirect, true}, acc ->
          max_redirs = Keyword.get(request.options, :max_redirect, 5)
          ["-L --max-redirs #{max_redirs}" | acc]

        {:hackney, _}, _ ->
          throw({:error, :hackney_opts_not_supported})

        _, acc ->
          acc
      end)
      |> Enum.join(" ")

    {scheme_opts, url} =
      case URI.parse(request.url) do
        %URI{scheme: "http+unix"} = uri ->
          uri = %URI{uri | scheme: "http", host: nil, authority: nil}
          {"--unix-socket #{uri.host}", URI.to_string(uri)}

        _ ->
          {"", request.url}
      end

    method = "-X " <> (request.method |> to_string() |> String.upcase())
    headers = request.headers |> Enum.map(fn {k, v} -> "-H '#{k}: #{v}'" end) |> Enum.join(" ")

    body =
      case HTTPoison.Base.maybe_process_form(request.body) do
        "" -> ""
        {:file, filename} -> "-d @#{filename}"
        {:form, form} -> form |> Enum.map(fn {k, v} -> "-F '#{k}=#{v}'" end) |> Enum.join(" ")
        {:stream, stream} -> "-d '#{Enum.join(stream, "")}'"
        {:multipart, _} -> throw({:error, :multipart_not_supported})
        body when is_binary(body) -> "-d '#{body}'"
        _ -> ""
      end

    {:ok,
     [
       "curl",
       options,
       scheme_opts,
       method,
       headers,
       body,
       url
     ]
     |> Enum.map(&String.trim/1)
     |> Enum.filter(&(&1 != ""))
     |> Enum.join(" ")}
  catch
    e -> e
  end
end

defmodule HTTPoison.Response do
  defstruct status_code: nil, body: nil, headers: [], request_url: nil, request: nil

  @type t :: %__MODULE__{
          status_code: integer,
          body: term,
          headers: list,
          request: HTTPoison.Request.t(),
          request_url: HTTPoison.Request.url()
        }
end

defmodule HTTPoison.AsyncResponse do
  defstruct id: nil
  @type t :: %__MODULE__{id: reference}
end

defmodule HTTPoison.AsyncStatus do
  defstruct id: nil, code: nil
  @type t :: %__MODULE__{id: reference, code: integer}
end

defmodule HTTPoison.AsyncHeaders do
  defstruct id: nil, headers: []
  @type t :: %__MODULE__{id: reference, headers: list}
end

defmodule HTTPoison.AsyncChunk do
  defstruct id: nil, chunk: nil
  @type t :: %__MODULE__{id: reference, chunk: binary}
end

defmodule HTTPoison.AsyncRedirect do
  defstruct id: nil, to: nil, headers: []
  @type t :: %__MODULE__{id: reference, to: String.t(), headers: list}
end

defmodule HTTPoison.AsyncEnd do
  defstruct id: nil
  @type t :: %__MODULE__{id: reference}
end

defmodule HTTPoison.MaybeRedirect do
  @moduledoc """
  If the option `:follow_redirect` is given to a request, HTTP redirects are automatically follow if
  the method is set to `:get` or `:head` and the response's `status_code` is `301`, `302` or `307`.

  If the method is set to `:post`, then the only `status_code` that get's automatically
  followed is `303`.

  If any other method or `status_code` is returned, then this struct is returned in place of a
  `HTTPoison.Response` or `HTTPoison.AsyncResponse`, containing the `redirect_url` to allow you
  to optionally re-request with the method set to `:get`.
  """

  defstruct status_code: nil, request_url: nil, request: nil, redirect_url: nil, headers: []

  @type t :: %__MODULE__{
          status_code: integer,
          headers: list,
          request: HTTPoison.Request.t(),
          request_url: HTTPoison.Request.url(),
          redirect_url: HTTPoison.Request.url()
        }
end

defmodule HTTPoison.Error do
  defexception reason: nil, id: nil
  @type t :: %__MODULE__{id: reference | nil, reason: any}

  def message(%__MODULE__{reason: reason, id: nil}), do: inspect(reason)
  def message(%__MODULE__{reason: reason, id: id}), do: "[Reference: #{id}] - #{inspect(reason)}"
end

defmodule HTTPoison do
  @moduledoc """
  The HTTP client for Elixir.

  The `HTTPoison` module can be used to issue HTTP requests and parse HTTP responses to arbitrary URLs.

      iex> HTTPoison.get!("https://api.github.com")
      %HTTPoison.Response{status_code: 200,
                          headers: [{"content-type", "application/json"}],
                          body: "{...}"}

  It's very common to use HTTPoison in order to wrap APIs, which is when the
  `HTTPoison.Base` module shines. Visit the documentation for `HTTPoison.Base`
  for more information.

  Under the hood, the `HTTPoison` module just uses `HTTPoison.Base` (as
  described in the documentation for `HTTPoison.Base`) without overriding any
  default function.

  See `request/5` for more details on how to issue HTTP requests
  """

  use HTTPoison.Base
end
