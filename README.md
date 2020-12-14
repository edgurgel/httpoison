![](https://i.imgur.com/WwqN8JO.png)
# HTTPoison [![Build Status](https://github.com/edgurgel/httpoison/workflows/CI/badge.svg?branch=master)](https://github.com/edgurgel/httpoison/actions?query=workflow%3ACI) [![Hex pm](https://img.shields.io/hexpm/v/httpoison.svg?style=flat)](https://hex.pm/packages/httpoison) [![hex.pm downloads](https://img.shields.io/hexpm/dt/httpoison.svg?style=flat)](https://hex.pm/packages/httpoison)

HTTP client for Elixir, based on
[HTTPotion](https://github.com/myfreeweb/httpotion)
([documentation](https://hexdocs.pm/httpoison/)).

## But... why something so similar to HTTPotion?

HTTPoison uses [hackney](https://github.com/benoitc/hackney) to execute HTTP requests instead of ibrowse. I like hackney :thumbsup:

Using hackney we work only with binaries instead of string lists.

## Installation

First, add HTTPoison to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:httpoison, "~> 1.7"}
  ]
end
```

and run `$ mix deps.get`. Add `:httpoison` to your applications list if your Elixir version is 1.3 or lower:

```elixir
def application do
  [applications: [:httpoison]]
end
```

## Usage

```elixir
iex> HTTPoison.start
iex> HTTPoison.get! "http://httparrot.herokuapp.com/get"
%HTTPoison.Response{
  body: "{\n  \"args\": {},\n  \"headers\": {} ...",
  headers: [{"Connection", "keep-alive"}, {"Server", "Cowboy"},
  {"Date", "Sat, 06 Jun 2015 03:52:13 GMT"}, {"Content-Length", "495"},
  {"Content-Type", "application/json"}, {"Via", "1.1 vegur"}],
  status_code: 200
}
iex> HTTPoison.get! "http://localhost:1"
** (HTTPoison.Error) :econnrefused
iex> HTTPoison.get "http://localhost:1"
{:error, %HTTPoison.Error{id: nil, reason: :econnrefused}}

iex> HTTPoison.post "http://httparrot.herokuapp.com/post", "{\"body\": \"test\"}", [{"Content-Type", "application/json"}]
{:ok, %HTTPoison.Response{body: "{\n  \"args\": {},\n  \"headers\": {\n    \"host\": \"httparrot.herokuapp.com\",\n    \"connection\": \"close\",\n    \"accept\": \"application/json\",\n    \"content-type\": \"application/json\",\n    \"user-agent\": \"hackney/1.6.1\",\n    \"x-request-id\": \"4b85de44-6227-4480-b506-e3b9b4f0318a\",\n    \"x-forwarded-for\": \"76.174.231.199\",\n    \"x-forwarded-proto\": \"http\",\n    \"x-forwarded-port\": \"80\",\n    \"via\": \"1.1 vegur\",\n    \"connect-time\": \"1\",\n    \"x-request-start\": \"1475945832992\",\n    \"total-route-time\": \"0\",\n    \"content-length\": \"16\"\n  },\n  \"url\": \"http://httparrot.herokuapp.com/post\",\n  \"origin\": \"10.180.37.142\",\n  \"form\": {},\n  \"data\": \"{\\\"body\\\": \\\"test\\\"}\",\n  \"json\": {\n    \"body\": \"test\"\n  }\n}",
    headers: [{"Connection", "keep-alive"}, {"Server", "Cowboy"},
    {"Date", "Sat, 08 Oct 2016 16:57:12 GMT"}, {"Content-Length", "681"},
    {"Content-Type", "application/json"}, {"Via", "1.1 vegur"}],
status_code: 200}}
```

You can also easily pattern match on the `HTTPoison.Response` struct:

```elixir
case HTTPoison.get(url) do
  {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
    IO.puts body
  {:ok, %HTTPoison.Response{status_code: 404}} ->
    IO.puts "Not found :("
  {:error, %HTTPoison.Error{reason: reason}} ->
    IO.inspect reason
end
```

### Options

There are a number of supported options(*not to be confused with the HTTP options method*), documented [here](https://hexdocs.pm/httpoison/HTTPoison.html#request/5), that can be added to your request. The example below shows the use of the `:ssl` and `:recv_timeout` options for a post request to an api that requires a bearer token. The `:ssl` option allows you to set options accepted by the [Erlang SSL module](https://erlang.org/doc/man/ssl.html), and `:recv_timeout` sets a timeout on receiving a response, the default is 5000ms.

```elixir
token = "some_token_from_another_request"
url = "https://example.com/api/endpoint_that_needs_a_bearer_token"
headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 500]
{:ok, response} = HTTPoison.get(url, headers, options)
```

And the example below shows the use of the `:ssl` options for a post request to an api that requires a client certification.

```elixir
url = "https://example.org/api/endpoint_that_needs_client_cert"
options = [ssl: [certfile: "certs/client.crt"]]
{:ok, response} = HTTPoison.post(url, [], options)
```

### Wrapping `HTTPoison.Base`

You can also use the `HTTPoison.Base` module in your modules in order to make
cool API clients or something. The following example wraps `HTTPoison.Base` in
order to build a client for the GitHub API
([Poison](https://github.com/devinus/poison) is used for JSON decoding):

```elixir
defmodule GitHub do
  use HTTPoison.Base

  @expected_fields ~w(
    login id avatar_url gravatar_id url html_url followers_url
    following_url gists_url starred_url subscriptions_url
    organizations_url repos_url events_url received_events_url type
    site_admin name company blog location email hireable bio
    public_repos public_gists followers following created_at updated_at
  )

  def process_request_url(url) do
    "https://api.github.com" <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!
    |> Map.take(@expected_fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end
end
```

```elixir
iex> GitHub.start
iex> GitHub.get!("/users/myfreeweb").body[:public_repos]
37
```

It's possible to extend the functions listed below:

```elixir
def process_request_body(body), do: body

def process_request_headers(headers) when is_map(headers) do
  Enum.into(headers, [])
end

def process_request_headers(headers), do: headers

def process_request_options(options), do: options

def process_request_url(url), do: url

def process_response_body(body), do: body

def process_response_chunk(chunk), do: chunk

def process_response_headers(headers), do: headers

def process_response_status_code(status_code), do: status_code
```

### Async requests

HTTPoison now comes with async requests!

```elixir
iex> HTTPoison.get! "https://github.com/", %{}, stream_to: self
%HTTPoison.AsyncResponse{id: #Reference<0.0.0.1654>}
iex> flush
%HTTPoison.AsyncStatus{code: 200, id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncHeaders{headers: %{"Connection" => "keep-alive", ...}, id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncChunk{chunk: "<!DOCTYPE html>...", id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncEnd{id: #Reference<0.0.0.1654>}
:ok
```

**Warning: this option can flood a receiver in messages.**

If a server may send very large messages the `async: :once` option should be used.
This will send only a single chunk at a time the receiver can call `HTTPoison.stream_next/1` to indicate ability to process more chunks.

### Cookies

HTTPoison allows you to send cookies:

```elixir
iex> HTTPoison.get!("http://httparrot.herokuapp.com/cookies", %{}, hackney: [cookie: ["session=a933ec1dd923b874e691; logged_in=true"]])
%HTTPoison.Response{body: "{\n  \"cookies\": {\n    \"session\": \"a933ec1dd923b874e691\",\n    \"logged_in\": \"true\"\n  }\n}",
 headers: [{"Connection", "keep-alive"}, ...],
 status_code: 200}
```

You can also receive cookies from the server by reading the `"set-cookie"` headers in the response:

```elixir
iex(1)> response = HTTPoison.get!("http://httparrot.herokuapp.com/cookies/set?foo=1")
iex(2)> cookies = Enum.filter(response.headers, fn
...(2)> {key, _} -> String.match?(key, ~r/\Aset-cookie\z/i)
...(2)> end)
[{"Set-Cookie", "foo=1; Version=1; Path=/"}]
```

You can see more usage examples in the test files (located in the
[`test/`](test)) directory.

### Connection Pools

Normally **hackney** [opens and closes connections on demand](https://github.com/benoitc/hackney#reuse-a-connection), but it also creates a [default pool](https://github.com/benoitc/hackney#use-the-default-pool) of connections which are reused for requests to the same host. If the connection and host support keepalive, the connection is kept open until explicitly closed.

To use the default pool, you can just declare it as an option:

```elixir
HTTPoison.get("httpbin.org/get", [], hackney: [pool: :default])
```

It is possible to use different pools for different purposes when a more fine grained allocation of resources is necessary.

#### Simple pool declaration

The easiest way is to just pass the name of the pool, and hackney will create it if it doesn't exist. Pools are independent from each other (they won't compete for connections) and are created with the default configuration.

```elixir
HTTPoison.get("httpbin.org/get", [], hackney: [pool: :first_pool])
HTTPoison.get("httpbin.org/get", [], hackney: [pool: :second_pool])
```

#### Explicit pool creation

If you want to use different configuration options you can create a pool manually [when your app starts](https://elixir-lang.org/getting-started/mix-otp/supervisor-and-application.html#the-application-callback) with `:hackney_pool.start_pool/2`.

```elixir
:ok = :hackney_pool.start_pool(:first_pool, [timeout: 15000, max_connections: 100])
```

From the already linked [hackney's readme](https://github.com/benoitc/hackney#use-the-default-pool):

> `timeout` is the time we keep the connection alive in the pool, `max_connections` is the number of connections maintained in the pool. Each connection in a pool is monitored and closed connections are removed automatically.

#### Pools as supervised processes

A third option is to add the pool as part of your supervision tree:

```elixir
children = [
  :hackney_pool.child_spec(:first_pool, [timeout: 15000, max_connections: 100])
]
```

Add that to the application supervisor and `first_pool` will be available to be used by HTTPoison/hackney.

### Multipart

#### Request

HTTPoison supports making `multipart` requests. E.g. with a local file:

```elixir
HTTPoison.post("https://myurl.php", {:multipart, [{:file, "test.txt", {"form-data", [{"name", "mytest"}, {"filename", "test.txt"}]}, []}]})
```

Sometimes you may already have the file contents in memory and want to upload
it elsewhere. A common example is fetching the file from a service like S3 and
uploading it somewhere else. There is no need to persist the file locally, you
can do the below:

```elixir
binary_file_content = "Something you fetched and now have it in memory"
token = "some_token_from_another_request"
headers = ["Authorization": "Bearer #{token}", {"Content-Type", "multipart/form-data"}]
options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 500]

HTTPoison.request(
  :post,
  "https://myurl.com",
  {:multipart,
   [{"file", binary_file_content, {"form-data", [name: "file", filename: "a_file_name.txt"]}, []}]},
  headers,
  options
)
```

Further examples of `multipart` requests can be found [in the issues](https://github.com/edgurgel/httpoison/issues?utf8=%E2%9C%93&q=is%3Aissue+multipart) (e.g.: [here](https://github.com/edgurgel/httpoison/issues/144#issue-160035453) and [here](https://github.com/edgurgel/httpoison/issues/237#issuecomment-313132804)).

For more complex queries regarding multipart requests, you should follow the [hackney docs for the `multipart` API](https://github.com/benoitc/hackney#send-a-body).

#### Response

HTTPoison supports parsing `multipart` responses. E.g.:

```elixir
iex(1)> response = %HTTPoison.Response{
...(1)>   body: "--123\r\nContent-type: application/json\r\n\r\n{\"1\": \"first\"}\r\n--123\r\nContent-type: application/json\r\n\r\n{\"2\": \"second\"}\r\n--123--\r\n",
...(1)>   headers: [{"Content-Type", "multipart/mixed;boundary=123"}],
...(1)>   request_url: "http://localhost",
...(1)>   status_code: 200
...(1)> }
%HTTPoison.Response{
  body: "--123\r\nContent-type: application/json\r\n\r\n{\"1\": \"first\"}\r\n--123\r\nContent-type: application/json\r\n\r\n{\"2\": \"second\"}\r\n--123--\r\n",
  headers: [{"Content-Type", "multipart/mixed;boundary=123"}],
  request_url: "http://localhost",
  status_code: 200
}

iex(2)> HTTPoison.Handlers.Multipart.decode_body(response)
[
  {[{"Content-Type", "application/json"}], "{\"1\": \"first\"}"},
  {[{"Content-Type", "application/json"}], "{\"2\": \"second\"}"}
]
```

For more complex queries regarding multipart response parsing, you should follow the [hackney docs for the `hackney_multipart` API](https://github.com/benoitc/hackney/blob/master/doc/hackney_multipart.md).

### Logging

If you're running on top of hackney (which you probably are) there's a handy way to get detailed request logging:

```
:hackney_trace.enable(:max, :io)
```

Just throw this in your code before your HTTPoison call and you'll get low-level log output.

## License

    Copyright © 2013-present Eduardo Gurgel <eduardo@gurgel.me>

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
