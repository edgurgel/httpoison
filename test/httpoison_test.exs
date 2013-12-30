Code.require_file "../test_helper.exs", __FILE__

defmodule HTTPoisonTest do
  use ExUnit.Case, async: true
  import PathHelpers

  test "get" do
    assert_response HTTPoison.get("httpbin.org"), fn(response) ->
      assert match?(<<60, 33, 68, 79, _ :: binary>>, response.body)
    end
  end

  test "head" do
    assert_response HTTPoison.head("httpbin.org/get"), fn(response) ->
      assert response.body == ""
    end
  end

  test "post charlist body" do
    assert_response HTTPoison.post("httpbin.org/post", 'test')
  end

  test "post binary body" do
    { :ok, file } = File.read(fixture_path("image.png"))

    assert_response HTTPoison.post("httpbin.org/post", file)
  end

  test "put" do
    assert_response HTTPoison.put("httpbin.org/put", "test")
  end

  test "patch" do
    assert_response HTTPoison.patch("httpbin.org/patch", "test")
  end

  test "delete" do
    assert_response HTTPoison.delete("httpbin.org/delete")
  end

  test "options" do
    assert_response HTTPoison.options("httpbin.org/get"), fn(response) ->
      assert response.headers["Content-Length"] == "0"
      assert is_binary(response.headers["Allow"])
    end
  end

  test "hackney option" do
    hackney = [follow_redirect: true]
    assert_response HTTPoison.get("http://httpbin.org/redirect-to?url=http%3A%2F%2Fhttpbin.org%2Fget", [], [ hackney: hackney ])
  end

  test "explicit http scheme" do
    assert_response HTTPoison.head("http://httpbin.org/get")
  end

  test "https scheme" do
    assert_response HTTPoison.head("https://httpbin.org/get")
  end

  test "char list URL" do
    assert_response HTTPoison.head('httpbin.org/get')
  end

  test "exception" do
    assert_raise HTTPoison.HTTPError, "econnrefused", fn ->
      HTTPoison.get "localhost:1"
    end
  end

  test "extension" do
    defmodule TestClient do
      use HTTPoison.Base

      def process_url(url) do
        self <- :ok
        super(url)
      end
    end

    TestClient.head("httpbin.org/get")
    assert_receive :ok, 1_000
  end

  test "asynchronous request" do
    HTTPoison.AsyncResponse[id: id] = HTTPoison.get "httpbin.org/get", [], [stream_to: self]

    assert_receive HTTPoison.AsyncStatus[id: ^id, code: 200], 1_000
    assert_receive HTTPoison.AsyncHeaders[id: ^id, headers: _headers], 1_000
    assert_receive HTTPoison.AsyncChunk[id: ^id, chunk: _chunk], 1_000
    assert_receive HTTPoison.AsyncEnd[id: ^id], 1_000
  end

  defp assert_response(response, function // nil) do
    assert response.status_code == 200
    assert response.headers["Connection"] == "keep-alive"
    assert is_binary(response.body)

    unless function == nil, do: function.(response)
  end
end
