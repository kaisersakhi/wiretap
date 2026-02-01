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
end
