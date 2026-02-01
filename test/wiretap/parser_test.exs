defmodule Wiretap.ParserTest do
  use ExUnit.Case
  doctest Wiretap.Parser

  alias Wiretap.Parser

  describe "new/0" do
    test "creates a new parser with initial state" do
      parser = Parser.new()

      assert parser.state == :headers
      assert parser.buffer == ""
      assert parser.headers == nil
      assert parser.content_length == 0
    end
  end

  describe "feed/2" do
    test "buffers incoming data" do
      parser = Parser.new()
      parser = Parser.feed(parser, "GET / HTTP/1.1\r\n")

      assert parser.buffer == "GET / HTTP/1.1\r\n"
      assert parser.state == :headers
    end

    test "buffers multiple chunks" do
      parser = Parser.new()
      parser =
        parser
        |> Parser.feed("GET / ")
        |> Parser.feed("HTTP/1.1\r\n")

      assert parser.buffer == "GET / HTTP/1.1\r\n"
    end
  end

  describe "parse_headers/1" do
    test "parses headers" do
      parser = Parser.new()
      parser = Parser.feed(parser, "GET / HTTP/1.1\r\nHost: example.com\r\n")
      parser = Parser.feed(parser, "User-Agent: Elixir\r\n")
      parser = Parser.feed(parser, "Content-Len")
      parser = Parser.feed(parser, "gth: 0\r\n")
      parser = Parser.feed(parser, "\r\n")

      assert parser.headers == %{
        "host" => "example.com",
        "method" => "GET",
        "path" => "/",
        "http_version" => "HTTP/1.1",
        "user-agent" => "Elixir",
        "content-length" => "0"
      }
      assert parser.content_length == "0"
      assert parser.state == :body
    end
  end

  describe "parse_body/1" do
    test "parses body" do
      parser = Parser.new()
      parser = Parser.feed(parser, "GET / HTTP/1.1\r\nHost: example.com\r\n")
      parser = Parser.feed(parser, "User-Agent: Elixir\r\n")
      parser = Parser.feed(parser, "Content-Len")
      parser = Parser.feed(parser, "gth: 13\r\n")
      parser = Parser.feed(parser, "\r\n")
      {:done, request, rest, parser} = Parser.feed(parser, "Hello, World!")

      assert request.body == "Hello, World!"
      assert parser.state == :done
    end
  end



end
