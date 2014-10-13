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
    expect(:hackney, :request, [{[:post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, [connect_timeout: 5000]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert Example.post!("localhost", "body") ==
    %HTTPoison.Response{ status_code: {:code, 200},
                         headers: {:headers, "headers"},
                         body: {:resp_body, "response"} }

    assert validate :hackney
  end

  test "request body using ExampleDefp" do
    expect(:hackney, :request, [{[:post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, [connect_timeout: 5000]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert ExampleDefp.post!("localhost", "body") ==
    %HTTPoison.Response{ status_code: {:code, 200},
                         headers: {:headers, "headers"},
                         body: {:resp_body, "response"} }

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
end
