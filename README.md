![](http://i.imgur.com/WwqN8JO.png)
# HTTPoison [![Build Status](https://travis-ci.org/edgurgel/httpoison.png?branch=master)](https://travis-ci.org/edgurgel/httpoison)

HTTP client for Elixir, based on [HTTPotion](https://github.com/myfreeweb/httpotion)

## But... why something so similar to HTTPotion?

HTTPoison uses hackney to execute HTTP requests instead of ibrowse. I like hackney :thumbsup:

Using hackney we work only with binaries instead of string lists.

## Usage

```iex
iex> HTTPoison.start
:ok
iex> HTTPoison.get "http://localhost:4000"
HTTPoison.Response[body: "...", headers: [{"Connection","Keep-Alive"}...], status_code: 200]
iex> HTTPoison.get "http://localhost:1"
** (HTTPoison.HTTPError) econnrefused
```

You can also extend it to make cool API clients or something (this example uses [jsex](https://github.com/talentdeficit/jsex) for JSON):

```elixir
defmodule GitHub do
  use HTTPoison.Base
  def process_url(url) do
    "https://api.github.com/" <> url
  end
  def process_response_body(body) do
    json = JSEX.decode! body
    json = Enum.map json, fn ({k, v}) -> { binary_to_atom(k), v } end
    json
  end
end

iex> GitHub.start
iex> GitHub.get("users/myfreeweb").body[:public_repos]
37
```

And now with async!

```iex
iex> HTTPoison.get "http://floatboth.com", [], [stream_to: self]
HTTPoison.AsyncResponse[id: #Reference<0.0.0.608>]
iex> flush
HTTPoison.AsyncStatus[id: #Reference<0.0.0.608>, code: 200]
HTTPoison.AsyncHeaders[id: #Reference<0.0.0.608>,
 headers: [{"Server", "cloudflare-nginx"}, {"Date", "Sun, 29 Dec 2013 17:54:24 GMT"}, {"Content-Type", "text/html; charset=utf-8"}, {"Transfer-Encoding", "chunked"}, {"Connection", "keep-alive"},
  {"Set-Cookie", "__cfduid=d845959e83669e83df85ce135a9585c031388339664499; expires=Mon, 23-Dec-2019 23:50:00 GMT; path=/; domain=.floatboth.com; HttpOnly"}, {"CF-RAY", "e485af71dfd0326"}]]
HTTPoison.AsyncChunk[id: #Reference<0.0.0.608>,
 chunk: "<!DOCTYPE html>..."]
HTTPoison.AsyncChunk[id: #Reference<0.0.0.608>,
 chunk: "curity, typography..."]
HTTPoison.AsyncEnd[id: #Reference<0.0.0.608>]
```

## License

Copyright © 2013 Eduardo Gurgel <eduardo@gurgel.me>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the COPYING file for more details.

