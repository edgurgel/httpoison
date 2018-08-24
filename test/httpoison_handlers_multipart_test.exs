defmodule HTTPoison.Handlers.MultipartTest do
  use ExUnit.Case, async: true

  @multipart_body "--123\r\nContent-type: application/json\r\n\r\n{\"1\": \"first\"}\r\n--123\r\nContent-type: application/json\r\n\r\n{\"2\": \"second\"}\r\n--123--\r\n"
  @non_multipart_body "response"

  test "decodes multipart body" do
    response = %HTTPoison.Response{
      body: @multipart_body,
      headers: [{"Content-Type", "multipart/mixed;boundary=123"}],
      request_url: "http://localhost",
      status_code: 200
    }

    assert HTTPoison.Handlers.Multipart.decode_body(response) == [
             {[{"Content-Type", "application/json"}], "{\"1\": \"first\"}"},
             {[{"Content-Type", "application/json"}], "{\"2\": \"second\"}"}
           ]
  end

  test "does not decode body if not multipart" do
    response = %HTTPoison.Response{
      body: @non_multipart_body,
      headers: "headers",
      request_url: "http://localhost",
      status_code: 200
    }

    assert HTTPoison.Handlers.Multipart.decode_body(response) == response.body
  end
end
