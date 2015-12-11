![](http://i.imgur.com/WwqN8JO.png)
# HTTPoison [![Build Status](https://travis-ci.org/edgurgel/httpoison.svg?branch=master)](https://travis-ci.org/edgurgel/httpoison) [![Hex pm](http://img.shields.io/hexpm/v/httpoison.svg?style=flat)](https://hex.pm/packages/httpoison) [![hex.pm downloads](https://img.shields.io/hexpm/dt/httpoison.svg?style=flat)](https://hex.pm/packages/httpoison)

HTTP client for Elixir, based on
[HTTPotion](https://github.com/myfreeweb/httpotion)
([documentation](http://hexdocs.pm/httpoison/)).

## But... why something so similar to HTTPotion?

HTTPoison uses [hackney](https://github.com/benoitc/hackney) to execute HTTP requests instead of ibrowse. I like hackney :thumbsup:

Using hackney we work only with binaries instead of string lists.

## Installation

First, add HTTPoison to your `mix.exs` dependencies:

```elixir
def deps do
  [{:httpoison, "~> 0.8.0"}]
end
```

and run `$ mix deps.get`. Now, list the `:httpoison` application as your
application dependency:

```elixir
def application do
  [applications: [:httpoison]]
end
```

### If you're on Ubuntu
Make sure you have `erlang-dev` installed before using `httpoison`.
You can do so by running:
```sh
apt-get install erlang-dev
```

## Usage

```iex
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

  def process_url(url) do
    "https://api.github.com" <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!
    |> Dict.take(@expected_fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end
end
```

```iex
iex> GitHub.start
iex> GitHub.get!("/users/myfreeweb").body[:public_repos]
37
```

It's possible to extend the functions listed below:

```elixir
defp process_request_body(body), do: body

defp process_response_body(body), do: body

defp process_request_headers(headers) when is_map(headers) do
  Enum.into(headers, [])
end

defp process_request_headers(headers), do: headers

defp process_response_chunk(chunk), do: chunk

defp process_headers(headers), do: headers

defp process_status_code(status_code), do: status_code
```

### Async requests

HTTPoison now comes with async requests!

```iex
iex> HTTPoison.get! "https://github.com/", %{}, stream_to: self
%HTTPoison.AsyncResponse{id: #Reference<0.0.0.1654>}
iex> flush
%HTTPoison.AsyncStatus{code: 200, id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncHeaders{headers: %{"Connection" => "keep-alive", ...}, id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncChunk{chunk: "<!DOCTYPE html>...", id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncEnd{id: #Reference<0.0.0.1654>}
:ok
```

You can see more usage examples in the test files (located in the
[`test/`](test)) directory.

## License

    Copyright © 2013-2014 Eduardo Gurgel <eduardo@gurgel.me>

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
