defmodule HTTPoisonTest do
  use ExUnit.Case, async: true
  import PathHelpers

  test "get" do
    assert_response(HTTPoison.get("localhost:8080/deny"), fn response ->
      assert :erlang.size(response.body) == 197
    end)
  end

  test "get with params" do
    resp = HTTPoison.get("localhost:8080/get", [], params: %{foo: "bar", baz: "bong"})

    assert_response(resp, fn response ->
      args = JSX.decode!(response.body)["args"]
      assert args["foo"] == "bar"
      assert args["baz"] == "bong"
      assert args |> Map.keys() |> length == 2
    end)
  end

  test "get with params in url and options" do
    resp =
      HTTPoison.get(
        "localhost:8080/get?bar=zing&foo=first",
        [],
        params: [{"foo", "second"}, {"baz", "bong"}]
      )

    assert_response(resp, fn response ->
      args = JSX.decode!(response.body)["args"]
      assert args["foo"] == ["first", "second"]
      assert args["baz"] == "bong"
      assert args["bar"] == "zing"
      assert args |> Map.keys() |> length == 3
    end)
  end

  test "head" do
    assert_response(HTTPoison.head("localhost:8080/get"), fn response ->
      assert response.body == ""
    end)
  end

  test "post charlist body" do
    assert_response(HTTPoison.post("localhost:8080/post", 'test'))
  end

  test "post binary body" do
    {:ok, file} = File.read(fixture_path("image.png"))

    assert_response(HTTPoison.post("localhost:8080/post", file))
  end

  test "post form data" do
    assert_response(
      HTTPoison.post("localhost:8080/post", {:form, [key: "value"]}, %{
        "Content-type" => "application/x-www-form-urlencoded"
      }),
      fn response ->
        Regex.match?(~r/"key".*"value"/, response.body)
      end
    )
  end

  test "put" do
    assert_response(HTTPoison.put("localhost:8080/put", "test"))
  end

  test "put without body" do
    assert_response(HTTPoison.put("localhost:8080/put"))
  end

  test "patch" do
    assert_response(HTTPoison.patch("localhost:8080/patch", "test"))
  end

  test "delete" do
    assert_response(HTTPoison.delete("localhost:8080/delete"))
  end

  test "options" do
    assert_response(HTTPoison.options("localhost:8080/get"), fn response ->
      assert get_header(response.headers, "content-length") == "0"
      assert is_binary(get_header(response.headers, "allow"))
    end)
  end

  test "option follow redirect absolute url" do
    assert_response(
      HTTPoison.get(
        "http://localhost:8080/redirect-to?url=http%3A%2F%2Flocalhost:8080%2Fget",
        [],
        follow_redirect: true
      )
    )
  end

  test "option follow redirect relative url" do
    assert_response(
      HTTPoison.get("http://localhost:8080/relative-redirect/1", [], follow_redirect: true)
    )
  end

  test "basic_auth hackney option" do
    hackney = [basic_auth: {"user", "pass"}]

    assert_response(
      HTTPoison.get("http://localhost:8080/basic-auth/user/pass", [], hackney: hackney)
    )
  end

  test "explicit http scheme" do
    assert_response(HTTPoison.head("http://localhost:8080/get"))
  end

  test "https scheme" do
    httparrot_priv_dir = :code.priv_dir(:httparrot)
    cacert_file = "#{httparrot_priv_dir}/ssl/server-ca.crt"
    cert_file = "#{httparrot_priv_dir}/ssl/server.crt"
    key_file = "#{httparrot_priv_dir}/ssl/server.key"

    assert_response(
      HTTPoison.get(
        "https://localhost:8433/get",
        [],
        ssl: [cacertfile: cacert_file, keyfile: key_file, certfile: cert_file]
      )
    )
  end

  test "http+unix scheme" do
    if Application.get_env(:httparrot, :unix_socket, false) do
      case {HTTParrot.unix_socket_supported?(), Application.fetch_env(:httparrot, :socket_path)} do
        {true, {:ok, path}} ->
          path = URI.encode_www_form(path)
          assert_response(HTTPoison.get("http+unix://#{path}/get"))

        _ ->
          :ok
      end
    end
  end

  test "char list URL" do
    assert_response(HTTPoison.head('localhost:8080/get'))
  end

  test "request headers as a map" do
    map_header = %{"X-Header" => "X-Value"}
    assert HTTPoison.get!("localhost:8080/get", map_header).body =~ "X-Value"
  end

  test "cached request" do
    if_modified = %{"If-Modified-Since" => "Tue, 11 Dec 2012 10:10:24 GMT"}
    response = HTTPoison.get!("localhost:8080/cache", if_modified)
    assert %HTTPoison.Response{status_code: 304, body: ""} = response
  end

  test "send cookies" do
    response = HTTPoison.get!("localhost:8080/cookies", %{}, hackney: [cookie: ["foo=1; bar=2"]])

    assert response.body
           |> String.replace(~r/\s|\r?\n/, "")
           |> String.replace(~r/\"/, "'")
           |> JSX.decode!() == %{"cookies" => %{"foo" => "1", "bar" => "2"}}
  end

  test "receive cookies" do
    response = HTTPoison.get!("localhost:8080/cookies/set?foo=1&bar=2")
    has_foo = Enum.member?(response.headers, {"set-cookie", "foo=1; Version=1; Path=/"})
    has_bar = Enum.member?(response.headers, {"set-cookie", "bar=2; Version=1; Path=/"})
    assert has_foo and has_bar
  end

  test "exception" do
    assert HTTPoison.get("localhost:1" == {:error, %HTTPoison.Error{reason: :econnrefused}})

    assert_raise HTTPoison.Error, ":econnrefused", fn ->
      HTTPoison.get!("localhost:1")
    end
  end

  test "asynchronous request" do
    {:ok, %HTTPoison.AsyncResponse{id: id}} =
      HTTPoison.get("localhost:8080/get", [], stream_to: self())

    assert_receive %HTTPoison.AsyncStatus{id: ^id, code: 200}, 1_000
    assert_receive %HTTPoison.AsyncHeaders{id: ^id, headers: headers}, 1_000
    assert_receive %HTTPoison.AsyncChunk{id: ^id, chunk: _chunk}, 1_000
    assert_receive %HTTPoison.AsyncEnd{id: ^id}, 1_000
    assert is_list(headers)
  end

  test "asynchronous request with explicit streaming using [async: :once]" do
    {:ok, resp = %HTTPoison.AsyncResponse{id: id}} =
      HTTPoison.get("localhost:8080/get", [], stream_to: self(), async: :once)

    assert_receive %HTTPoison.AsyncStatus{id: ^id, code: 200}, 100

    refute_receive %HTTPoison.AsyncHeaders{id: ^id, headers: _headers}, 100
    {:ok, ^resp} = HTTPoison.stream_next(resp)
    assert_receive %HTTPoison.AsyncHeaders{id: ^id, headers: headers}, 100

    refute_receive %HTTPoison.AsyncChunk{id: ^id, chunk: _chunk}, 100
    {:ok, ^resp} = HTTPoison.stream_next(resp)
    assert_receive %HTTPoison.AsyncChunk{id: ^id, chunk: _chunk}, 100

    refute_receive %HTTPoison.AsyncEnd{id: ^id}, 100
    {:ok, ^resp} = HTTPoison.stream_next(resp)
    assert_receive %HTTPoison.AsyncEnd{id: ^id}, 100

    assert is_list(headers)
  end

  test "asynchronous redirected get request" do
    {:ok, %HTTPoison.AsyncResponse{id: id}} =
      HTTPoison.get(
        "localhost:8080/redirect/2",
        [],
        stream_to: self(),
        hackney: [follow_redirect: true]
      )

    assert_receive %HTTPoison.AsyncRedirect{id: ^id, to: to, headers: headers}, 1_000
    assert to == "http://localhost:8080/redirect/1"
    assert is_list(headers)
  end

  test "multipart upload" do
    response =
      HTTPoison.post(
        "localhost:8080/post",
        {:multipart, [{:file, "test/test_helper.exs"}, {"name", "value"}]}
      )

    assert_response(response)
  end

  test "post streaming body" do
    expected = %{"some" => "bytes"}
    enumerable = JSX.encode!(expected) |> String.split("")
    headers = %{"Content-type" => "application/json"}
    response = HTTPoison.post("localhost:8080/post", {:stream, enumerable}, headers)
    assert_response(response)
    {:ok, %HTTPoison.Response{body: body}} = response

    assert JSX.decode!(body)["json"] == expected
  end

  test "max_body_length limits body size" do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, {:active, false}, {:packet, :raw}])
    {:ok, [buffer: buffer_size]} = :inet.getopts(socket, [:buffer])
    :ok = :gen_tcp.close(socket)

    max_length = Kernel.trunc(buffer_size * 1.5)

    expected_length =
      Float.ceil(max_length / buffer_size)
      |> Kernel.*(buffer_size)
      |> Kernel.trunc()

    resp = HTTPoison.get("localhost:8080/stream/20", [], max_body_length: max_length)

    assert_response(resp, fn response ->
      assert byte_size(response.body) <= expected_length
      assert byte_size(response.body) >= max_length
    end)
  end

  defp assert_response({:ok, response}, function \\ nil) do
    assert is_list(response.headers)
    assert response.status_code == 200
    assert is_binary(response.body)

    unless function == nil, do: function.(response)
  end

  defp get_header(headers, key) do
    headers
    |> Enum.filter(fn {k, _} -> k == key end)
    |> hd
    |> elem(1)
  end
end
