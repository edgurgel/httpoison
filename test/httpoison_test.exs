defmodule HTTPoisonTest do
  use ExUnit.Case, async: true
  import PathHelpers
  alias Jason
  alias HTTPoison.Request

  test "get" do
    assert_response(HTTPoison.get("localhost:4002/deny"), fn response ->
      assert :erlang.size(response.body) == 197
    end)
  end

  test "get with params" do
    resp = HTTPoison.get("localhost:4002/get", [], params: %{foo: "bar", baz: "bong"})

    assert_response(resp, fn response ->
      args = Jason.decode!(response.body)["args"]
      assert args["foo"] == "bar"
      assert args["baz"] == "bong"
      assert args |> Map.keys() |> length == 2

      assert {:ok, "curl -X GET http://localhost:4002/get?" <> query} =
               Request.to_curl(response.request)

      assert %{"baz" => "bong", "foo" => "bar"} == URI.decode_query(query)
    end)
  end

  test "get with params in url and options" do
    resp =
      HTTPoison.get(
        "localhost:4002/get?bar=zing&foo=first",
        [],
        params: [{"foo", "second"}, {"baz", "bong"}]
      )

    assert_response(resp, fn response ->
      args = Jason.decode!(response.body)["args"]
      assert args["foo"] == ["first", "second"]
      assert args["baz"] == "bong"
      assert args["bar"] == "zing"
      assert args |> Map.keys() |> length == 3

      assert Request.to_curl(response.request) ==
               {:ok,
                "curl -X GET http://localhost:4002/get?bar=zing&foo=first&foo=second&baz=bong"}
    end)
  end

  test "head" do
    assert_response(HTTPoison.head("localhost:4002/get"), fn response ->
      assert response.body == ""
      assert Request.to_curl(response.request) == {:ok, "curl -X HEAD http://localhost:4002/get"}
    end)
  end

  test "post charlist body" do
    assert_response(HTTPoison.post("localhost:4002/post", ~c"test"), fn response ->
      assert Request.to_curl(response.request) == {:ok, "curl -X POST http://localhost:4002/post"}
    end)
  end

  test "post binary body" do
    {:ok, file} = File.read(fixture_path("image.png"))

    assert_response(HTTPoison.post("localhost:4002/post", file), fn response ->
      assert Request.to_curl(response.request) ==
               {:ok, "curl -X POST -d '#{file}' http://localhost:4002/post"}
    end)
  end

  test "post form data" do
    assert_response(
      HTTPoison.post("localhost:4002/post", {:form, [key: "value"]}, %{
        "Content-type" => "application/x-www-form-urlencoded"
      }),
      fn response ->
        Regex.match?(~r/"key".*"value"/, response.body)

        assert Request.to_curl(response.request) ==
                 {:ok,
                  "curl -X POST -H 'Content-type: application/x-www-form-urlencoded' -F 'key=value' http://localhost:4002/post"}
      end
    )
  end

  test "post nested form data when given as keyword list" do
    assert_response(
      HTTPoison.post(
        "localhost:4002/post",
        {:form, [not_nested: [1, 2], nested: [foo: "bar", again: [hello: "world"]]]},
        %{"Content-type" => "application/x-www-form-urlencoded"}
      ),
      fn %HTTPoison.Response{request: request} = response ->
        assert {:form,
                [{:not_nested, [1, 2]}, {"nested[foo]", "bar"}, {"nested[again][hello]", "world"}]} =
                 request.body

        Regex.match?(~r/"not_nested".*\x01\x02/, response.body)
        Regex.match?(~r/"nested\[foo\]".*"bar"/, response.body)
        Regex.match?(~r/"nested\[again\]\[hello\]".*"world"/, response.body)

        assert Request.to_curl(response.request) ==
                 {:ok,
                  "curl -X POST -H 'Content-type: application/x-www-form-urlencoded' -F 'not_nested=\x01\x02' -F 'nested[foo]=bar' -F 'nested[again][hello]=world' http://localhost:4002/post"}
      end
    )
  end

  test "post nested form data when given as map (no order guaranteed)" do
    assert_response(
      HTTPoison.post(
        "localhost:4002/post",
        {:form, %{not_nested: [1, 2], nested: %{foo: "bar", again: %{hello: "world"}}}},
        %{"Content-type" => "application/x-www-form-urlencoded"}
      ),
      fn %HTTPoison.Response{request: request} = response ->
        assert {:form, body} = request.body

        assert [{:not_nested, [1, 2]}, {"nested[foo]", "bar"}, {"nested[again][hello]", "world"}]
               |> MapSet.new()
               |> MapSet.equal?(MapSet.new(body))

        Regex.match?(~r/"not_nested".*\x01\x02/, response.body)
        Regex.match?(~r/"nested\[foo\]".*"bar"/, response.body)
        Regex.match?(~r/"nested\[again\]\[hello\]".*"world"/, response.body)

        assert {:ok,
                "curl -X POST -H 'Content-type: application/x-www-form-urlencoded'" <> form_params} =
                 Request.to_curl(response.request)

        assert form_params =~ "-F 'not_nested=\x01\x02'"
        assert form_params =~ "-F 'nested[foo]=bar'"
        assert form_params =~ "-F 'nested[again][hello]=world'"
      end
    )
  end

  test "put" do
    assert_response(HTTPoison.put("localhost:4002/put", "test"), fn response ->
      assert Request.to_curl(response.request) ==
               {:ok, "curl -X PUT -d 'test' http://localhost:4002/put"}
    end)
  end

  test "put without body" do
    assert_response(HTTPoison.put("localhost:4002/put"), fn response ->
      assert Request.to_curl(response.request) ==
               {:ok, "curl -X PUT http://localhost:4002/put"}
    end)
  end

  test "patch" do
    assert_response(HTTPoison.patch("localhost:4002/patch", "test"), fn response ->
      assert Request.to_curl(response.request) ==
               {:ok, "curl -X PATCH -d 'test' http://localhost:4002/patch"}
    end)
  end

  test "delete" do
    assert_response(HTTPoison.delete("localhost:4002/delete"), fn response ->
      assert Request.to_curl(response.request) ==
               {:ok, "curl -X DELETE http://localhost:4002/delete"}
    end)
  end

  test "options" do
    assert_response(HTTPoison.options("localhost:4002/get"), fn response ->
      assert get_header(response.headers, "content-length") == "0"
      assert is_binary(get_header(response.headers, "allow"))

      assert Request.to_curl(response.request) ==
               {:ok, "curl -X OPTIONS http://localhost:4002/get"}
    end)
  end

  test "option follow redirect absolute url" do
    assert_response(
      HTTPoison.get(
        "http://localhost:4002/redirect-to?url=http%3A%2F%2Flocalhost:4002%2Fget",
        [],
        follow_redirect: true
      ),
      fn response ->
        assert Request.to_curl(response.request) ==
                 {:ok,
                  "curl -L --max-redirs 5 -X GET http://localhost:4002/redirect-to?url=http%3A%2F%2Flocalhost:4002%2Fget"}
      end
    )
  end

  test "option follow redirect relative url" do
    assert_response(
      HTTPoison.get("http://localhost:4002/relative-redirect/1", [], follow_redirect: true),
      fn response ->
        assert Request.to_curl(response.request) ==
                 {:ok, "curl -L --max-redirs 5 -X GET http://localhost:4002/relative-redirect/1"}
      end
    )
  end

  test "basic_auth hackney option" do
    hackney = [basic_auth: {"user", "pass"}]

    assert_response(
      HTTPoison.get("http://localhost:4002/basic-auth/user/pass", [], hackney: hackney)
    )
  end

  test "explicit http scheme" do
    assert_response(HTTPoison.head("http://localhost:4002/get"), fn response ->
      assert Request.to_curl(response.request) ==
               {:ok, "curl -X HEAD http://localhost:4002/get"}
    end)
  end

  test "http+unix scheme" do
    if Application.get_env(:httparrot, :unix_socket, false) do
      case {HTTParrot.unix_socket_supported?(), Application.fetch_env(:httparrot, :socket_path)} do
        {true, {:ok, path}} ->
          path = URI.encode_www_form(path)

          assert_response(
            HTTPoison.get("http+unix://#{path}/get"),
            fn response ->
              assert Request.to_curl(response.request) ==
                       {:ok, "curl --unix-socket #{path} -X GET http:/get"}
            end
          )

        _ ->
          :ok
      end
    end
  end

  test "char list URL" do
    assert_response(HTTPoison.head(~c"localhost:4002/get"), fn response ->
      assert Request.to_curl(response.request) ==
               {:ok, "curl -X HEAD http://localhost:4002/get"}
    end)
  end

  test "request headers as a map" do
    map_header = %{"X-Header" => "X-Value"}
    assert response = HTTPoison.get!("localhost:4002/get", map_header)
    assert response.body =~ "X-Value"

    assert Request.to_curl(response.request) ==
             {:ok, "curl -X GET -H 'X-Header: X-Value' http://localhost:4002/get"}
  end

  test "cached request" do
    if_modified = %{"If-Modified-Since" => "Tue, 11 Dec 2012 10:10:24 GMT"}
    response = HTTPoison.get!("localhost:4002/cache", if_modified)
    assert %HTTPoison.Response{status_code: 304, body: ""} = response

    assert Request.to_curl(response.request) ==
             {:ok,
              "curl -X GET -H 'If-Modified-Since: Tue, 11 Dec 2012 10:10:24 GMT' http://localhost:4002/cache"}
  end

  test "send cookies" do
    response = HTTPoison.get!("localhost:4002/cookies", %{}, hackney: [cookie: ["foo=1; bar=2"]])
    assert Jason.decode!(response.body) == %{"cookies" => %{"foo" => "1", "bar" => "2"}}
  end

  test "receive cookies" do
    response = HTTPoison.get!("localhost:4002/cookies/set?foo=1&bar=2")
    has_foo = Enum.member?(response.headers, {"set-cookie", "foo=1; Version=1; Path=/"})
    has_bar = Enum.member?(response.headers, {"set-cookie", "bar=2; Version=1; Path=/"})
    assert has_foo and has_bar

    assert Request.to_curl(response.request) ==
             {:ok, "curl -X GET http://localhost:4002/cookies/set?foo=1&bar=2"}
  end

  test "exception" do
    assert HTTPoison.get("localhost:1" == {:error, %HTTPoison.Error{reason: :econnrefused}})

    assert_raise HTTPoison.Error, ":econnrefused", fn ->
      HTTPoison.get!("localhost:1")
    end
  end

  test "asynchronous request" do
    {:ok, %HTTPoison.AsyncResponse{id: id}} =
      HTTPoison.get("localhost:4002/get", [], stream_to: self())

    assert_receive %HTTPoison.AsyncStatus{id: ^id, code: 200}, 1_000
    assert_receive %HTTPoison.AsyncHeaders{id: ^id, headers: headers}, 1_000
    assert_receive %HTTPoison.AsyncChunk{id: ^id, chunk: _chunk}, 1_000
    assert_receive %HTTPoison.AsyncEnd{id: ^id}, 1_000
    assert is_list(headers)
  end

  test "asynchronous request with explicit streaming using [async: :once]" do
    {:ok, resp = %HTTPoison.AsyncResponse{id: id}} =
      HTTPoison.get("localhost:4002/get", [], stream_to: self(), async: :once)

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
        "localhost:4002/redirect/2",
        [],
        stream_to: self(),
        hackney: [follow_redirect: true]
      )

    assert_receive %HTTPoison.AsyncRedirect{id: ^id, to: to, headers: headers}, 1_000
    assert to == "http://localhost:4002/redirect/1"
    assert is_list(headers)
  end

  test "multipart upload" do
    response =
      HTTPoison.post(
        "localhost:4002/post",
        {:multipart, [{:file, "test/test_helper.exs"}, {"name", "value"}]}
      )

    assert_response(response)
  end

  test "post streaming body" do
    expected = %{"some" => "bytes"}
    enumerable = Jason.encode!(expected) |> String.split("")
    headers = %{"Content-type" => "application/json"}
    response = HTTPoison.post("localhost:4002/post", {:stream, enumerable}, headers)

    assert_response(response, fn response ->
      assert Jason.decode!(response.body)["json"] == expected

      assert Request.to_curl(response.request) ==
               {:ok,
                "curl -X POST -H 'Content-type: application/json' -d '{\"some\":\"bytes\"}' http://localhost:4002/post"}
    end)
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

    resp = HTTPoison.get("localhost:4002/stream/20", [], max_body_length: max_length)

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

  describe "ssl config tests" do
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
        ),
        fn response ->
          assert Request.to_curl(response.request) ==
                   {:ok,
                    "curl --cert #{cert_file} --key #{key_file} --cacert #{cacert_file} -X GET https://localhost:8433/get"}
        end
      )
    end

    test "expired certificate" do
      assert {:error, %HTTPoison.Error{reason: {:tls_alert, {:certificate_expired, reason}}}} =
               HTTPoison.get("https://expired.badssl.com/")

      assert to_string(reason) =~ "Certificate Expired"
      # TLS version should not matter
      assert {:error, %HTTPoison.Error{reason: {:tls_alert, _}}} =
               HTTPoison.get("https://expired.badssl.com/", [], ssl: [{:versions, [:"tlsv1.2"]}])

      assert {:ok, _} =
               HTTPoison.get("https://expired.badssl.com/", [], ssl: [{:verify, :verify_none}])

      # Can be disabled via verify_fun
      assert {:ok, _} =
               HTTPoison.get("https://expired.badssl.com/", [],
                 ssl: [
                   verify_fun:
                     {fn _, reason, state ->
                        case reason do
                          {:bad_cert, :cert_expired} -> {:valid, state}
                          {:bad_cert, :unknown_ca} -> {:valid, state}
                          {:extension, _} -> {:valid, state}
                          :valid -> {:valid, state}
                          :valid_peer -> {:valid, state}
                          error -> {:fail, error}
                        end
                      end, []}
                 ]
               )
    end

    test "allows changing TLS1.0 settings" do
      assert {:error,
              %HTTPoison.Error{
                reason: {:tls_alert, {:protocol_version, reason}}
              }} =
               HTTPoison.get("https://tls-v1-0.badssl.com:1010/", [],
                 ssl: [{:versions, [:"tlsv1.2"]}]
               )

      assert to_string(reason) =~ "Protocol Version"

      if :tlsv1 in :ssl.versions()[:available] do
        assert {:ok, _} =
                 HTTPoison.get("https://tls-v1-0.badssl.com:1010/", [],
                   ssl: [
                     {:versions, [:tlsv1]}
                   ]
                 )
      end
    end

    test "allows changing TLS1.1 settings" do
      assert {:error,
              %HTTPoison.Error{
                reason: {:tls_alert, {:protocol_version, reason}}
              }} =
               HTTPoison.get("https://tls-v1-1.badssl.com:1011/", [],
                 ssl: [versions: [:"tlsv1.2", :tlsv1]]
               )

      assert to_string(reason) =~ "Protocol Version"

      if :"tlsv1.1" in :ssl.versions()[:available] do
        assert {:ok, _} =
                 HTTPoison.get("https://tls-v1-1.badssl.com:1011/", [],
                   ssl: [versions: [:"tlsv1.1"]]
                 )
      end
    end

    test "does support tls1.2" do
      if :"tlsv1.2" in :ssl.versions()[:supported] do
        assert {:ok, _} = HTTPoison.get("https://tls-v1-2.badssl.com:1012/", [])
      end

      if :"tlsv1.2" in :ssl.versions()[:available] do
        assert {:ok, _} =
                 HTTPoison.get("https://tls-v1-2.badssl.com:1012/", [],
                   ssl: [versions: [:"tlsv1.2"]]
                 )
      end
    end

    test "invalid common name" do
      assert {:error,
              %HTTPoison.Error{
                reason: {:tls_alert, {:handshake_failure, reason}}
              }} = HTTPoison.get("https://wrong.host.badssl.com/")

      assert to_string(reason) =~ ~r"hostname|altnames"

      assert {:error,
              %HTTPoison.Error{
                reason: {:tls_alert, _}
              }} =
               HTTPoison.get("https://wrong.host.badssl.com/", [],
                 ssl: [{:versions, [:"tlsv1.2"]}]
               )
    end
  end
end
