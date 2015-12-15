defmodule BencodingTest do
  use ExUnit.Case
  doctest Bencoding

  test "Encodings" do
    assert Bencoding.encode(123)     == "i123e"
    assert Bencoding.encode("hello") == "5:hello"
    assert Bencoding.encode([1,2,3]) == "li1ei2ei3ee"
    assert Bencoding.encode(true)    == "i1e"
    assert Bencoding.encode(false)   == "i0e"
    assert Bencoding.encode(%{:cow=>"moo", :spam=>"eggs" }) == "d3:cow3:moo4:spam4:eggse"
  end


  test "Decodings" do
    assert Bencoding.decode("i123e") == {123, ""}
    assert Bencoding.decode("5:hello") == {"hello", ""}
    assert Bencoding.decode("i123e5:hello") == {123, "5:hello"}
    assert Bencoding.decode("d3:cow3:moo4:spam4:eggse") == {%{cow: "moo", spam: "eggs"}, ""}

    assert Bencoding.decode("i123eabcdef") ==   {123, "abcdef"}
  end


  test "Back and Forth" do
    val = 54321
    {check,_} = Bencoding.decode( Bencoding.encode(val) )
    assert check == val

    val = "hello world"
    {check,_} = Bencoding.decode( Bencoding.encode(val) )
    assert check == val

    val = [10, 20, "good", "bye", 18]
    {check,_} = Bencoding.decode( Bencoding.encode(val) )
    assert check == val

    val = %{ :first => 1, :last => "another", :another => 449988}
    {check,_} = Bencoding.decode( Bencoding.encode(val) )
    assert check == val
  end

end
