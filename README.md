![](http://i.imgur.com/WwqN8JO.png)
# HTTPoison [![Build Status](https://travis-ci.org/edgurgel/httpoison.svg?branch=master)](https://travis-ci.org/edgurgel/httpoison) [![Hex pm](http://img.shields.io/hexpm/v/httpoison.svg?style=flat)](https://hex.pm/packages/httpoison)

HTTP client for Elixir, based on
[HTTPotion](https://github.com/myfreeweb/httpotion)
([documentation](http://hexdocs.pm/httpoison/)).

## But... why something so similar to HTTPotion?

HTTPoison uses hackney to execute HTTP requests instead of ibrowse. I like hackney :thumbsup:

Using hackney we work only with binaries instead of string lists.

## Installation

1. Add HTTPoison to your `mix.exs` dependencies:

```elixir
def deps do
  [{:httpoison, "~> 0.6"}]
end
```

2. List `:httpoison` as your application dependencies:

```elixir
def application do
  [applications: [:httpoison]]
end
```

## Usage

```iex
iex> HTTPoison.start
iex> HTTPoison.get! "http://httparrot.herokuapp.com/get"
%HTTPoison.Response{
  body: "{\n  \"args\": {},\n  \"headers\": {} ...",
  headers: %{"connection" => "keep-alive", "content-length" => "517", ...},
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

  def process_url(url) do
    "https://api.github.com" <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!
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

defp process_headers(headers), do: Enum.into(headers, %{})

defp process_status_code(status_code), do: status_code
```

### Async requests

HTTPoison now comes with async requests!

```iex
iex> HTTPoison.get! "http://floatboth.com", %{}, stream_to: self
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

