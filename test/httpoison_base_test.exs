Code.require_file "test_helper.exs", __DIR__

defmodule HTTPoisonBaseTest do
  use ExUnit.Case
  import :meck

  defmodule Example do
    use HTTPoison.Base
    def process_url(url), do: "http://" <> url
    def process_request_body(body), do: {:req_body, body}
    def process_response_body(body), do: {:resp_body, body}
    def process_headers(headers), do: {:headers, headers}
    def process_status_code(code), do: {:code, code}
  end

  setup do
    new :hackney
  end

  teardown do
    unload :hackney
  end

  test "request body" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], {:req_body, "body"}, [connect_timeout: 5000]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert Example.post("localhost", "body") ==
      HTTPoison.Response[status_code: {:code, 200},
                         headers: {:headers, "headers"},
                         body: {:resp_body, "response"}]

    assert validate :hackney
  end
end
