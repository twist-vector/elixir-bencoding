# Bittorrent Protocol Encoding and Decoding

The *Bencoding* module is an implementation of the Bittorrent ascii protocol.
The Bittorrent protocol uses an ASCII representation of three basic types;
integers, booleans, and strings.  In addition to the composite types lists and
dictionaries of the basic types.

For the Bittorrent encoding spec, see [https://wiki.theory.org/BitTorrentSpecification#Bencoding](https://wiki.theory.org/BitTorrentSpecification#Bencoding)

## Supported
   - Booleans (as integers)
   - Strings
   - Integers
   - Lists of mixed strings, integers, and/or booleans
   - String indexed dictionaries of mixed strings, integers, and/or booleans

## Examples

### Encoding

Encoding base types is simple.  Calling the `encode` function with a supported
type will execute the correct function and return the encoded string.
```elixir
IO.puts Bencoding.encode(123)
```
the resulting output would be
```
i123e
```
Encoding all the supported types...
```
IO.puts Bencoding.encode(123)
IO.puts Bencoding.encode("hello")
IO.puts Bencoding.encode([1,2,3])
IO.puts Bencoding.encode(true)
IO.puts Bencoding.encode(%{:cow=>"moo", :spam=>"eggs" })
```
will give the following:
```
i123e
5:hello
li1ei2ei3ee
i1e
d3:cow3:moo4:spam4:eggse
```
Note that there is no boolean type directly supported b y the protocol.  Instead
booleans are encoded as integers with values of 0 or 1.

### Decoding
Decoding of the protocol is a little more complicated.  It is anticipated that
the decoding of individual pieces of data occurs in the larger context of
parsing a received longer sting.  As such, the decode methods return a pair:
the first element is the decoded value, the second is the remaining bytes of
the binary.  So
```
Bencoding.decode("i123e")
```
results in `{123, ""}` while
```
Bencoding.decode("i123ei123ei123e")
```
results in `{123, "i123ei123e"}`.  To extract the decoded value and ignore the
rest of the bytes is simple:
```elixir
{value,_} = Bencoding.decode("i123ei123ei123e")
```
will result in `value=123`.


## Caveats and TODO
Error handling isn't the best.  Malformed Bencoded strings may result in
unhelpful exceptions being thrown.
