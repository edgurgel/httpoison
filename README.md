![](http://i.imgur.com/WwqN8JO.png)
# HTTPoison [![Build Status](https://travis-ci.org/edgurgel/httpoison.png?branch=master)](https://travis-ci.org/edgurgel/httpoison)

HTTP client for Elixir, based on [HTTPotion](https://github.com/myfreeweb/httpotion)

## But... why something so similar to HTTPotion?

HTTPoison uses hackney to execute HTTP requests instead of ibrowse. I like hackney :thumbsup:

Using hackney we work only with binaries instead of string lists.

## Installation

Be aware that for now, `hackney` is not on http://hex.pm. If you are using hex
dependencies you will need to add hackney as dependency.

1. Adding HTTPoison to your `mix.exs` dependencies:

  ```elixir
  def deps do
    [
      {:httpoison, "~> 0.3"}
      {:hackney,   github: "benoitc/hackney", tag: "0.13.0" }
    ]
  end
  ```

2. List the `:httpoison` as your application dependencies:

  ```elixir
  def application do
    [applications: [:httpoison]]
  end
  ```

## Usage

```iex
iex> HTTPoison.start
{:ok, [:crypto, :asn1, :public_key, :ssl, :idna, :hackney, :httpoison]}
iex> HTTPoison.get "http://httparrot.herokuapp.com/get"
%HTTPoison.Response{body: "{\n  \"args\": {},\n  \"headers\": {\n    \"host\": \"httparrot.herokuapp.com\",\n    \"connection\": \"close\",\n    \"user-agent\": \"hackney/0.12.1\",\n    \"x-request-id\": \"690c0c03-c42c-4781-bfa1-97ae0a1e6e05\",\n    \"x-forwarded-for\": \"103.21.172.205\",\n    \"x-forwarded-proto\": \"http\",\n    \"x-forwarded-port\": \"80\",\n    \"via\": \"vegur\",\n    \"connect-time\": \"3\",\n    \"x-request-start\": \"1398767078381\",\n    \"total-route-time\": \"0\",\n    \"content-length\": \"0\"\n  },\n  \"url\": \"http://httparrot.herokuapp.com/get\",\n  \"origin\": \"10.6.103.177\"\n}",
 headers: %{"connection" => "keep-alive", "content-length" => "517",
  "content-type" => "application/json",
  "date" => "Tue, 29 Apr 2014 10:24:38 GMT", "server" => "Cowboy",
  "via" => "vegur"}, status_code: 200}
iex> HTTPoison.get "http://localhost:1"
** (HTTPoison.HTTPError) econnrefused
    (httpoison) lib/httpoison.ex:131: HTTPoison.request/5
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
    json = Enum.map json, fn ({k, v}) -> { String.to_atom(k), v } end
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
%HTTPoison.AsyncResponse{id: #Reference<0.0.0.1654>}
iex> flush
{:ssl_closed, {:sslsocket, {:gen_tcp, #Port<0.5438>, :tls_connection}, #PID<0.143.0>}}
%HTTPoison.AsyncStatus{code: 200, id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncHeaders{headers: %{"CF-RAY" => "122ace7ae0f00b08-SYD", "Connection" => "keep-alive", "Content-Type" => "text/html; charset=utf-8", "Date" => "Tue, 29 Apr 2014 10:27:22 GMT",
  "Server" => "cloudflare-nginx", "Set-Cookie" => "__cfduid=d8491e9bdd48e92628c4f529e028083841398767241423; expires=Mon, 23-Dec-2019 23:50:00 GMT; path=/; domain=.floatboth.com; HttpOnly",
  "Transfer-Encoding" => "chunked"}, id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncChunk{chunk: "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\" /><meta content=\"width=device-width, initial-scale=1.0\" name=\"viewport\" /><title>{ float: both }</title><link href=\"/style.css\" rel=\"stylesheet\" /><link href=\"/articles.xml\" rel=\"alternate\" type=\"application/atom+xml\" /></head><body class=\"landing\"><section><div class=\"logo-wrapper\"><img alt=\"float: both\" class=\"logo\" src=\"/static/logo-white.svg\" title=\"float: both\" /></div><p>Welcome to { float: both }.</p>\n\n<p>This is some kind of personal website&hellip; for some kind of person.\nHow exactly are they different from any other person?\nWhile no one has tried to study the exact difference, some observations have been made. If&nbsp;you follow this person on <a href=\"https://alpha.app.net/myfreeweb\" rel=\"me\" class=\"secret\">a certain social media service</a>, you might be able to know them better.\nAlso, a particular government agency used its big data analysis tools on this person, as they do with every single human being who could not resist using the amazing thing we know as the internet, and the keywords they have associated with this person are the following, in no particular order: programming, design, gadgets, music, security, typography, privacy, accessibility, photography, web, procrastination, technology, <em>REDACTED</em>.</p>\n</section><section><ul id=\"posts\"><li><a href=\"/the-problem-with-push-notifications\">The Problem with Push Notifications</a></li><li><a href=\"/where-i-think-about-plain-text\">where I think about plain text</a></li><li><a href=\"/where-i-have-ideas-about-blogging\">where I have ideas about blogging</a></li><li><a href=\"/where-i-compare-python-and-ruby\">where I compare Python &amp; Ruby</a></li><li><a href=\"/where-i-remember-not-everything\">where I remember not everything</a></li><li><a href=\"/where-i-think-about-auth\">where I think about authentication</a></li><li><a href=\"/where-i-set-up-my-git-and-hg-aliases-like-a-boss\">where I set up my git &amp; hg aliases</a></li><li><a href=\"/where-i-introduce-devproxy\">where I introduce devproxy</a></li><li><a href=\"/where-i-compare-saas-to-something\">where I compare SAAS to something</a></li></ul></section></body></html>",
 id: #Reference<0.0.0.1654>}
%HTTPoison.AsyncEnd{id: #Reference<0.0.0.1654>}
:ok
```

## License

    Copyright © 2013-2014 Eduardo Gurgel <eduardo@gurgel.me>

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.

