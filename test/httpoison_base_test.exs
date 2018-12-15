defmodule HTTPoisonBaseTest do
  use ExUnit.Case, async: true
  import Mimic

  setup :verify_on_exit!

  defmodule DeprecatedExample do
    use HTTPoison.Base
    def process_url(url), do: "http://" <> url
    def process_request_body(body), do: {:req_body, body}
    def process_request_headers(headers), do: {:req_headers, headers}
    def process_request_options(options), do: Keyword.put(options, :timeout, 10)
    def process_response_body(body), do: {:resp_body, body}
    def process_headers(headers), do: {:headers, headers}
    def process_status_code(code), do: {:code, code}
  end

  defmodule Example do
    use HTTPoison.Base
    def process_request_url(url), do: "http://" <> url
    def process_request_body(body), do: {:req_body, body}
    def process_request_headers(headers), do: {:req_headers, headers}
    def process_request_options(options), do: Keyword.put(options, :timeout, 10)
    def process_response_body(body), do: {:resp_body, body}
    def process_response_headers(headers), do: {:headers, headers}
    def process_response_status_code(code), do: {:code, code}
    def process_response(response), do: {:resp, response}
  end

  defmodule ExampleParamsOptions do
    use HTTPoison.Base
    def process_url(url), do: "http://" <> url

    def process_request_options(options),
      do: Keyword.merge(options, params: Map.merge(options[:params], %{key: "fizz"}))
  end

  setup do
    on_exit(fn ->
      System.delete_env("HTTP_PROXY")
      System.delete_env("http_proxy")
      System.delete_env("HTTPS_PROXY")
      System.delete_env("https_proxy")
      System.delete_env("NO_PROXY")
      System.delete_env("no_PROXY")
      System.delete_env("no_proxy")
    end)

    stub(:hackney)
    :ok
  end

  test "request body using Example" do
    expect(:hackney, :request, fn
      :post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, [connect_timeout: 10] ->
        {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert Example.post!("localhost", "body") ==
             {:resp,
              %HTTPoison.Response{
                status_code: {:code, 200},
                headers: {:headers, "headers"},
                body: {:resp_body, "response"},
                request_url: "http://localhost",
                request: %HTTPoison.Request{
                  body: {:req_body, "body"},
                  headers: {:req_headers, []},
                  method: :post,
                  options: [timeout: 10],
                  params: %{},
                  url: "http://localhost"
                }
              }}
  end

  test "request body using DeprecatedExample" do
    expect(:hackney, :request, fn
      :post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, [connect_timeout: 10] ->
        {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert DeprecatedExample.post!("localhost", "body") ==
             %HTTPoison.Response{
               status_code: {:code, 200},
               headers: {:headers, "headers"},
               body: {:resp_body, "response"},
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: {:req_body, "body"},
                 headers: {:req_headers, []},
                 method: :post,
                 options: [timeout: 10],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "request body using params example" do
    expect(:hackney, :request, fn :get, "http://localhost?foo=bar&key=fizz", [], "", [] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert ExampleParamsOptions.get!("localhost", [], params: %{foo: "bar"}) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost?foo=bar&key=fizz",
               request: %HTTPoison.Request{
                 body: "",
                 headers: [],
                 method: :get,
                 options: [params: %{foo: "bar", key: "fizz"}],
                 params: %{foo: "bar", key: "fizz"},
                 url: "http://localhost?foo=bar&key=fizz"
               }
             }
  end

  test "request raises error tuple" do
    reason = {:closed, "Something happened"}

    expect(:hackney, :request, fn _, _, _, _, _ -> {:error, reason} end)
    expect(:hackney, :request, fn _, _, _, _, _ -> {:error, reason} end)

    assert_raise HTTPoison.Error, "{:closed, \"Something happened\"}", fn ->
      HTTPoison.get!("http://localhost")
    end

    assert HTTPoison.get("http://localhost") == {:error, %HTTPoison.Error{reason: reason}}
  end

  test "passing connect_timeout option" do
    expect(:hackney, :request, fn
      :post, "http://localhost", [], "body", [connect_timeout: 12345] ->
        {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert HTTPoison.post!("localhost", "body", [], timeout: 12345) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [timeout: 12345],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "passing recv_timeout option" do
    expect(:hackney, :request, fn
      :post, "http://localhost", [], "body", [recv_timeout: 12345] ->
        {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert HTTPoison.post!("localhost", "body", [], recv_timeout: 12345) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [recv_timeout: 12345],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "passing proxy option" do
    expect_hackney_post_with_proxy("http://localhost", "proxy")

    assert HTTPoison.post!("localhost", "body", [], proxy: "proxy") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [proxy: "proxy"],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "passing socks5 options" do
    expect(:hackney, :request, fn
      :post,
      "http://localhost",
      [],
      "body",
      [
        socks5_pass: "secret",
        socks5_user: "user",
        proxy: {:socks5, 'localhost', 1080}
      ] ->
        {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert HTTPoison.post!(
             "localhost",
             "body",
             [],
             proxy: {:socks5, 'localhost', 1080},
             socks5_user: "user",
             socks5_pass: "secret"
           ) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [
                   proxy: {:socks5, 'localhost', 1080},
                   socks5_user: "user",
                   socks5_pass: "secret"
                 ],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "passing proxy option with proxy_auth" do
    expect(:hackney, :request, fn
      :post,
      "http://localhost",
      [],
      "body",
      [proxy_auth: {"username", "password"}, proxy: "proxy"] ->
        {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert HTTPoison.post!(
             "localhost",
             "body",
             [],
             proxy: "proxy",
             proxy_auth: {"username", "password"}
           ) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [proxy: "proxy", proxy_auth: {"username", "password"}],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "having http_proxy env variable set on http requests" do
    System.put_env("HTTP_PROXY", "proxy")

    expect_hackney_post_with_proxy("http://localhost", "proxy")

    assert HTTPoison.post!("localhost", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "having http_proxy env variable set on http requests as empty string" do
    System.put_env("HTTP_PROXY", "")

    expect_hackney_post_with_no_proxy("http://localhost")

    assert HTTPoison.post!("localhost", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "having https_proxy env variable set on https requests" do
    System.put_env("HTTPS_PROXY", "proxy")

    expect_hackney_post_with_proxy("https://localhost", "proxy")

    assert HTTPoison.post!("https://localhost", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "https://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [],
                 params: %{},
                 url: "https://localhost"
               }
             }
  end

  test "having https_proxy env variable set on http requests" do
    System.put_env("HTTPS_PROXY", "proxy")

    expect_hackney_post_with_no_proxy("http://localhost")

    assert HTTPoison.post!("localhost", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "having matching no_proxy env variable set with proxy env variable" do
    # If the variable is specified directly, no_proxy should be ignored.
    System.put_env("NO_PROXY", ".somedomain.com")

    expect_hackney_post_with_proxy("http://www.somedomain.com", "proxy")

    assert HTTPoison.post!("www.somedomain.com", "body", [], proxy: "proxy") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://www.somedomain.com",
               request: %HTTPoison.Request{
                 url: "http://www.somedomain.com",
                 body: "body",
                 method: :post,
                 options: [proxy: "proxy"]
               }
             }
  end

  test "having matching no_proxy env variable set with http_proxy env" do
    # If the variable is specified indirectly, no_proxy should be used.
    System.put_env("HTTP_PROXY", "proxy")
    System.put_env("NO_PROXY", ".somedomain.com")

    expect_hackney_post_with_no_proxy("http://www.somedomain.com")

    assert HTTPoison.post!("www.somedomain.com", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://www.somedomain.com",
               request: %HTTPoison.Request{
                 url: "http://www.somedomain.com",
                 body: "body",
                 method: :post
               }
             }
  end

  test "having no_proxy env variable set that does not match site" do
    System.put_env("HTTP_PROXY", "proxy")
    System.put_env("NO_PROXY", ".nonmatching.com")

    expect_hackney_post_with_proxy("http://www.somedomain.com", "proxy")

    assert HTTPoison.post!("http://www.somedomain.com", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://www.somedomain.com",
               request: %HTTPoison.Request{
                 url: "http://www.somedomain.com",
                 body: "body",
                 method: :post
               }
             }
  end

  test "having no_proxy env variable with multiple domains" do
    System.put_env("HTTP_PROXY", "proxy")
    System.put_env("NO_PROXY", ".nonmatching.com,.matching.com")

    expect_hackney_post_with_no_proxy("http://www.matching.com")

    assert HTTPoison.post!("http://www.matching.com", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://www.matching.com",
               request: %HTTPoison.Request{
                 url: "http://www.matching.com",
                 body: "body",
                 method: :post
               }
             }
  end

  test "having no_proxy env variable with wildcard domains" do
    System.put_env("HTTP_PROXY", "proxy")
    System.put_env("NO_PROXY", ".nonmatching.com,*.matching.com")

    expect_hackney_post_with_no_proxy("http://www.matching.com")

    assert HTTPoison.post!("http://www.matching.com", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://www.matching.com",
               request: %HTTPoison.Request{
                 url: "http://www.matching.com",
                 body: "body",
                 method: :post
               }
             }
  end

  test "having no_proxy env variable with non-matching wildcard domains" do
    System.put_env("HTTP_PROXY", "proxy")
    System.put_env("NO_PROXY", "*.nonmatching.com")

    expect_hackney_post_with_proxy("http://www.matching.com", "proxy")

    assert HTTPoison.post!("http://www.matching.com", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://www.matching.com",
               request: %HTTPoison.Request{
                 url: "http://www.matching.com",
                 body: "body",
                 method: :post
               }
             }
  end

  defp expect_hackney_post_with_proxy(url, proxy) do
    expect_hackney_post(url, proxy: proxy)
  end

  defp expect_hackney_post_with_no_proxy(url) do
    expect_hackney_post(url, [])
  end

  def expect_hackney_post(url, expected_options) do
    expect(:hackney, :request, fn
      :post, ^url, [], "body", ^expected_options -> {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)
  end

  test "passing ssl option" do
    expect(:hackney, :request, fn :post,
                                  "http://localhost",
                                  [],
                                  "body",
                                  [ssl_options: [certfile: "certs/client.crt"]] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert HTTPoison.post!("localhost", "body", [], ssl: [certfile: "certs/client.crt"]) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [ssl: [certfile: "certs/client.crt"]],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "passing follow_redirect option" do
    expect(:hackney, :request, fn :post,
                                  "http://localhost",
                                  [],
                                  "body",
                                  [follow_redirect: true] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert HTTPoison.post!("localhost", "body", [], follow_redirect: true) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [follow_redirect: true],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "passing max_redirect option" do
    expect(:hackney, :request, fn :post, "http://localhost", [], "body", [max_redirect: 2] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "response"} end)

    assert HTTPoison.post!("localhost", "body", [], max_redirect: 2) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost",
               request: %HTTPoison.Request{
                 body: "body",
                 headers: [],
                 method: :post,
                 options: [max_redirect: 2],
                 params: %{},
                 url: "http://localhost"
               }
             }
  end

  test "passing max_body_length option" do
    expect(:hackney, :request, fn :get, "http://localhost", [], "", [] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, :infinity -> {:ok, "response"} end)

    assert HTTPoison.get("localhost") ==
             {:ok,
              %HTTPoison.Response{
                status_code: 200,
                headers: "headers",
                body: "response",
                request_url: "http://localhost",
                request: %HTTPoison.Request{
                  body: "",
                  headers: [],
                  method: :get,
                  options: [],
                  params: %{},
                  url: "http://localhost"
                }
              }}

    expect(:hackney, :request, fn :get, "http://localhost", [], "", [] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :body, fn _, _ -> {:ok, "res"} end)

    assert HTTPoison.get("localhost", [], max_body_length: 3) ==
             {:ok,
              %HTTPoison.Response{
                status_code: 200,
                headers: "headers",
                body: "res",
                request_url: "http://localhost",
                request: %HTTPoison.Request{
                  body: "",
                  headers: [],
                  method: :get,
                  options: [max_body_length: 3],
                  params: %{},
                  url: "http://localhost"
                }
              }}
  end
end
