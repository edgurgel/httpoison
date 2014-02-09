Code.require_file "test_helper.exs", __DIR__

defmodule HTTPoisonTest do
  use ExUnit.Case, async: true
  import PathHelpers

  setup_all do
    :ok = Application.Behaviour.start(:httparrot)
  end

  test "get" do
    assert_response HTTPoison.get("localhost:8080/deny"), fn(response) ->
      assert size(response.body) == 197
    end
  end

  test "head" do
    assert_response HTTPoison.head("localhost:8080/get"), fn(response) ->
      assert response.body == ""
    end
  end

  test "post charlist body" do
    assert_response HTTPoison.post("localhost:8080/post", 'test')
  end

  test "post binary body" do
    { :ok, file } = File.read(fixture_path("image.png"))

    assert_response HTTPoison.post("localhost:8080/post", file)
  end

  test "put" do
    assert_response HTTPoison.put("localhost:8080/put", "test")
  end

  test "patch" do
    assert_response HTTPoison.patch("localhost:8080/patch", "test")
  end

  test "delete" do
    assert_response HTTPoison.delete("localhost:8080/delete")
  end

  test "options" do
    assert_response HTTPoison.options("localhost:8080/get"), fn(response) ->
      assert response.headers["content-length"] == "0"
      assert is_binary(response.headers["allow"])
    end
  end

  test "hackney option" do
    hackney = [follow_redirect: true]
    assert_response HTTPoison.get("http://localhost:8080/redirect-to?url=http%3A%2F%2Flocalhost:8080%2Fget", [], [ hackney: hackney ])
  end

  test "basic_auth hackney option" do
    hackney = [basic_auth: {"user", "pass"}]
    assert_response HTTPoison.get("http://localhost:8080/basic-auth/user/pass", [], [ hackney: hackney ])
  end

  test "explicit http scheme" do
    assert_response HTTPoison.head("http://localhost:8080/get")
  end

  test "https scheme" do
    assert_response HTTPoison.head("https://localhost:8433/get")
  end

  test "char list URL" do
    assert_response HTTPoison.head('localhost:8080/get')
  end

  test "exception" do
    assert_raise HTTPoison.HTTPError, "econnrefused", fn ->
      HTTPoison.get "localhost:1"
    end
  end

  test "asynchronous request" do
    HTTPoison.AsyncResponse[id: id] = HTTPoison.get "localhost:8080/get", [], [stream_to: self]

    assert_receive HTTPoison.AsyncStatus[id: ^id, code: 200], 1_000
    assert_receive HTTPoison.AsyncHeaders[id: ^id, headers: _headers], 1_000
    assert_receive HTTPoison.AsyncChunk[id: ^id, chunk: _chunk], 1_000
    assert_receive HTTPoison.AsyncEnd[id: ^id], 1_000
  end

  defp assert_response(response, function \\ nil) do
    assert response.status_code == 200
    assert response.headers["connection"] == "keep-alive"
    assert is_binary(response.body)

    unless function == nil, do: function.(response)
  end
end
