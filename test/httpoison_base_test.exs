defmodule HTTPoisonBaseTest do
  use ExUnit.Case
  import :meck

  defmodule Example do
    use HTTPoison.Base
    def process_url(url), do: "http://" <> url
    def process_request_body(body), do: {:req_body, body}
    def process_request_headers(headers), do: {:req_headers, headers}
    def process_response_body(body), do: {:resp_body, body}
    def process_headers(headers), do: {:headers, headers}
    def process_status_code(code), do: {:code, code}
  end

  defmodule ExampleDefp do
    use HTTPoison.Base
    defp process_url(url), do: "http://" <> url
    defp process_request_body(body), do: {:req_body, body}
    defp process_request_headers(headers), do: {:req_headers, headers}
    defp process_response_body(body), do: {:resp_body, body}
    defp process_headers(headers), do: {:headers, headers}
    defp process_status_code(code), do: {:code, code}
  end

  setup do
    new :hackney
    on_exit fn -> unload end
    :ok
  end

  test "request body using Example" do
    expect(:hackney, :request, [{[:post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, []],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert Example.post!("localhost", "body") ==
    %HTTPoison.Response{ status_code: {:code, 200},
                         headers: {:headers, "headers"},
                         body: {:resp_body, "response"},
                         location: "location" }

    assert validate :hackney
  end

  test "request body using ExampleDefp" do
    expect(:hackney, :request, [{[:post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, []],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert ExampleDefp.post!("localhost", "body") ==
    %HTTPoison.Response{ status_code: {:code, 200},
                         headers: {:headers, "headers"},
                         body: {:resp_body, "response"},
                         location: "location" }

    assert validate :hackney
  end

  test "request raises error tuple" do
    reason = {:closed, "Something happened"}
    expect(:hackney, :request, 5, {:error, reason})

    assert_raise HTTPoison.Error, "{:closed, \"Something happened\"}", fn ->
      HTTPoison.get!("http://localhost")
    end

    assert HTTPoison.get("http://localhost") == {:error, %HTTPoison.Error{reason: reason}}

    assert validate :hackney
  end

  test "passing connect_timeout option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [connect_timeout: 12345]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert HTTPoison.post!("localhost", "body", [], timeout: 12345) ==
    %HTTPoison.Response{ status_code: 200,
                         headers: "headers",
                         body: "response",
                         location: "location" }

    assert validate :hackney
  end

  test "passing recv_timeout option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [recv_timeout: 12345]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert HTTPoison.post!("localhost", "body", [], recv_timeout: 12345) ==
    %HTTPoison.Response{ status_code: 200,
                         headers: "headers",
                         body: "response",
                         location: "location" }

    assert validate :hackney
  end

  test "passing proxy option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [proxy: "proxy"]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert HTTPoison.post!("localhost", "body", [], proxy: "proxy") ==
    %HTTPoison.Response{ status_code: 200,
                         headers: "headers",
                         body: "response",
                         location: "location" }

    assert validate :hackney
  end

  test "passing proxy option with proxy_auth" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [proxy_auth: {"username", "password"}, proxy: "proxy"]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert HTTPoison.post!("localhost", "body", [], [proxy: "proxy", proxy_auth: {"username", "password"}]) ==
    %HTTPoison.Response{ status_code: 200,
                         headers: "headers",
                         body: "response",
                         location: "location" }

    assert validate :hackney
  end

  test "passing ssl option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [ssl_options: [certfile: "certs/client.crt"]]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert HTTPoison.post!("localhost", "body", [], ssl: [certfile: "certs/client.crt"]) ==
    %HTTPoison.Response{ status_code: 200,
                         headers: "headers",
                         body: "response",
                         location: "location" }

    assert validate :hackney
  end

  test "passing follow_redirect option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [follow_redirect: true]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert HTTPoison.post!("localhost", "body", [], follow_redirect: true) ==
    %HTTPoison.Response{ status_code: 200,
                         headers: "headers",
                         body: "response",
                         location: "location" }

    assert validate :hackney
  end

  test "passing max_redirect option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [max_redirect: 2]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})
    expect(:hackney, :location, 1, "location")

    assert HTTPoison.post!("localhost", "body", [], max_redirect: 2) ==
    %HTTPoison.Response{ status_code: 200,
                         headers: "headers",
                         body: "response",
                         location: "location" }

    assert validate :hackney
  end
end
