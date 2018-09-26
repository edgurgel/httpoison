defmodule HTTPoisonBaseTest do
  use ExUnit.Case, async: true
  import Mimic

  setup :verify_on_exit!

  defmodule Example do
    use HTTPoison.Base
    def process_url(url), do: "http://" <> url
    def process_request_body(body), do: {:req_body, body}
    def process_request_headers(headers), do: {:req_headers, headers}
    def process_request_options(options), do: Keyword.put(options, :timeout, 10)
    def process_response_body(body), do: {:resp_body, body}
    def process_headers(headers), do: {:headers, headers}
    def process_status_code(code), do: {:code, code}
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
    end)

    stub(:hackney)
    :ok
  end

  test "request body using Example" do
    expect(:hackney, :request, fn
      :post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, [connect_timeout: 10] ->
        {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert Example.post!("localhost", "body") ==
             %HTTPoison.Response{
               status_code: {:code, 200},
               headers: {:headers, "headers"},
               body: {:resp_body, "response"},
               request_url: "http://localhost"
             }
  end

  test "request body using params example" do
    expect(:hackney, :request, fn :get, "http://localhost?foo=bar&key=fizz", [], "", [] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert ExampleParamsOptions.get!("localhost", [], params: %{foo: "bar"}) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost?foo=bar&key=fizz"
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

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body", [], timeout: 12345) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
             }
  end

  test "passing recv_timeout option" do
    expect(:hackney, :request, fn
      :post, "http://localhost", [], "body", [recv_timeout: 12345] ->
        {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body", [], recv_timeout: 12345) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
             }
  end

  test "passing proxy option" do
    expect(:hackney, :request, fn
      :post, "http://localhost", [], "body", [proxy: "proxy"] -> {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body", [], proxy: "proxy") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
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

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

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
               request_url: "http://localhost"
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

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

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
               request_url: "http://localhost"
             }
  end

  test "having http_proxy env variable set on http requests" do
    System.put_env("HTTP_PROXY", "proxy")

    expect(:hackney, :request, fn
      :post, "http://localhost", [], "body", [proxy: "proxy"] -> {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
             }
  end

  test "having http_proxy env variable set on http requests as empty string" do
    System.put_env("HTTP_PROXY", "")

    expect(:hackney, :request, fn :post, "http://localhost", [], "body", [] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
             }
  end

  test "having https_proxy env variable set on https requests" do
    System.put_env("HTTPS_PROXY", "proxy")

    expect(:hackney, :request, fn :post, "https://localhost", [], "body", [proxy: "proxy"] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("https://localhost", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "https://localhost"
             }
  end

  test "having https_proxy env variable set on http requests" do
    System.put_env("HTTPS_PROXY", "proxy")

    expect(:hackney, :request, fn
      :post, "http://localhost", [], "body", [] -> {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body") ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
             }
  end

  test "passing ssl option" do
    expect(:hackney, :request, fn :post,
                                  "http://localhost",
                                  [],
                                  "body",
                                  [ssl_options: [certfile: "certs/client.crt"]] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body", [], ssl: [certfile: "certs/client.crt"]) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
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

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body", [], follow_redirect: true) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
             }
  end

  test "passing max_redirect option" do
    expect(:hackney, :request, fn :post, "http://localhost", [], "body", [max_redirect: 2] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.post!("localhost", "body", [], max_redirect: 2) ==
             %HTTPoison.Response{
               status_code: 200,
               headers: "headers",
               body: "response",
               request_url: "http://localhost"
             }
  end

  test "passing max_body_length option" do
    expect(:hackney, :request, fn :get, "http://localhost", [], "", [] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> :done end)

    assert HTTPoison.get("localhost") ==
             {:ok,
              %HTTPoison.Response{
                status_code: 200,
                headers: "headers",
                body: "response",
                request_url: "http://localhost"
              }}

    expect(:hackney, :request, fn :get, "http://localhost", [], "", [] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)

    assert HTTPoison.get("localhost", [], max_body_length: 3) ==
             {:error, %HTTPoison.Error{id: nil, reason: {:body_too_large, "response"}}}

    expect(:hackney, :request, fn :get, "http://localhost", [], "", [] ->
      {:ok, 200, "headers", :client}
    end)

    expect(:hackney, :stream_body, fn _ -> {:ok, "response"} end)
    expect(:hackney, :stream_body, fn _ -> {:ok, "additionalcontent"} end)

    assert HTTPoison.get("localhost", [], max_body_length: 12, partial_response: true) ==
             {:ok,
              %HTTPoison.Response{
                status_code: 200,
                headers: "headers",
                body: "responseadditionalcontent",
                request_url: "http://localhost"
              }}
  end
end
