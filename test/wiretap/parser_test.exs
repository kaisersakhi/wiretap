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
      {:more, parser} = Parser.feed(parser, "GET / HTTP/1.1\r\n")

      assert parser.buffer == "GET / HTTP/1.1\r\n"
      assert parser.state == :headers
    end

    test "buffers multiple chunks" do
      parser = Parser.new()
      {:more, parser} = Parser.feed(parser, "GET / ")
      {:more, parser} = Parser.feed(parser, "HTTP/1.1\r\n")

      assert parser.buffer == "GET / HTTP/1.1\r\n"
    end
  end

  describe "parse_headers/1" do
    test "parses headers" do
      parser = Parser.new()
      {:more, parser} = Parser.feed(parser, "GET / HTTP/1.1\r\nHost: example.com\r\n")
      {:more, parser} = Parser.feed(parser, "User-Agent: Elixir\r\n")
      {:more, parser} = Parser.feed(parser, "Content-Len")
      {:more, parser} = Parser.feed(parser, "gth: 0\r\n")
      {_, %Wiretap.Request{} = request, _rest, parser} = Parser.feed(parser, "\r\n")

      assert request.headers == %{
        "host" => "example.com",
        "method" => "GET",
        "path" => "/",
        "http_version" => "HTTP/1.1",
        "user-agent" => "Elixir",
        "content-length" => "0"
      }
      assert parser.content_length == 0
      assert parser.state == :done
    end
  end

  describe "parse_body/1" do
    test "parses body" do
      parser = Parser.new()
      {:more, parser} = Parser.feed(parser, "GET / HTTP/1.1\r\nHost: example.com\r\n")
      {:more, parser} = Parser.feed(parser, "User-Agent: Elixir\r\n")
      {:more, parser} = Parser.feed(parser, "Content-Len")
      {:more, parser} = Parser.feed(parser, "gth: 13\r\n")
      {:more, parser} = Parser.feed(parser, "\r\n")
      {:done, request, rest, parser} = Parser.feed(parser, "Hello, World!")

      assert request.body == "Hello, World!"
      assert parser.state == :done
    end
  end


  describe "when body is larger than content-length" do
    test "parses body and returns the rest" do
      parser = Parser.new()
      {:more, parser} = Parser.feed(parser, "GET / HTTP/1.1\r\nHost: example.com\r\n")
      {:more, parser} = Parser.feed(parser, "User-Agent: Elixir\r\n")
      {:more, parser} = Parser.feed(parser, "Content-Len")
      {:more, parser} = Parser.feed(parser, "gth: 13\r\n")
      {:more, parser} = Parser.feed(parser, "\r\n")
      {:done, request, rest, parser} = Parser.feed(parser, "Hello, World!Extra")

      IO.puts(request.body)

      assert parser.headers == %{
        "host" => "example.com",
        "method" => "GET",
        "path" => "/",
        "http_version" => "HTTP/1.1",
        "user-agent" => "Elixir",
        "content-length" => "13"
      }

      assert request.body == "Hello, World!"
      assert rest == "Extra"
      assert parser.state == :done
    end
  end

  describe "when body is smaller than content-length" do
    test "buffers the body and waits for more data" do
      parser = Parser.new()
      {:more, parser} = Parser.feed(parser, "GET / HTTP/1.1\r\nHost: example.com\r\n")
      {:more, parser} = Parser.feed(parser, "User-Agent: Elixir\r\n")
      {:more, parser} = Parser.feed(parser, "Content-Len")
      {:more, parser} = Parser.feed(parser, "gth: 13\r\n")
      {:more, parser} = Parser.feed(parser, "\r\n")

      {:more, parser} = Parser.feed(parser, "Hello, Worl") # Only 11 bytes, not 13

      assert parser.headers == %{
        "host" => "example.com",
        "method" => "GET",
        "path" => "/",
        "http_version" => "HTTP/1.1",
        "user-agent" => "Elixir",
        "content-length" => "13"
      }

      # assert request.body == "Hello, World!"
      # assert rest == "Extra"
      assert parser.state == :body
    end
  end

  describe "when body contains unicode characters" do
    test "parses body and returns the rest" do
      body = "Hello, Wörld! 😅"
      parser = Parser.new()
      {:more, parser} = Parser.feed(parser, "GET / HTTP/1.1\r\nHost: example.com\r\n")
      {:more, parser} = Parser.feed(parser, "User-Agent: Elixir\r\n")
      {:more, parser} = Parser.feed(parser, "Content-Len")
      {:more, parser} = Parser.feed(parser, "gth: #{byte_size(body)}\r\n")
      {:more, parser} = Parser.feed(parser, "\r\n")
      {:done, request, rest, parser} = Parser.feed(parser, body)

      assert parser.headers == %{
        "host" => "example.com",
        "method" => "GET",
        "path" => "/",
        "http_version" => "HTTP/1.1",
        "user-agent" => "Elixir",
        "content-length" => to_string(byte_size(body))
      }

      assert request.body == body
      assert parser.state == :done
    end
  end
end
