defmodule Bencoding do

    #
    # Encoders...
    #
    # 'encode' is overloaded for each input type.  That is, the correct function
    # is chosen based the type of the passed in parameter. Currently supports
    # integer, string (binary), list, boolean, and map (dict) types.
    #
    # The encoding (see http://www.bittorrent.org/beps/bep_0003.html) uses an
    # initial letter to indicate type, and a trailing 'e' to indicate the end.
    # Note that the string encoding is different in that the length is encoded,
    # followed by ':', followed by the string data.
    #
    # There is no pre-defined binary type in the bittorrent protocol, rather they
    # are encoded as integers with value 1 and 0.
    #
    def encode(int) when is_integer(int), do: "i#{int}e"
    def encode(str) when is_binary(str),  do: "#{byte_size(str)}:#{str}"
    def encode(list) when is_list(list),  do: "l#{Enum.map(list, &encode(&1))}e"
    def encode(true), do: "i1e"
    def encode(false), do: "i0e"
    def encode(dict) when is_map(dict) do
      "d" <> (dict
              |> Enum.to_list
              |> Enum.map( fn {k,v} -> encode(Atom.to_string(k)) <> encode(v) end )
              |> Enum.reduce( "", fn(x, acc) -> acc <> x end ))
          <> "e"
    end


    #
    # Decoders...
    #
    # 'decode' will select the underlying data type based on the first character
    # of the Bencoded string.  See the Bittorrent protocol spec at
    # http://www.bittorrent.org/beps/bep_0003.html.  The first letter indicates:
    #     i: integer
    #     l: list
    #     d: dictionary
    #     anything else: we'll assume it's a string which is encoded as #:data where
    #                    # is the length in bytes.
    #
    def decode(<<?i, tail :: binary>>), do: decode_int(tail, "")
    def decode(<<?l, tail :: binary>>), do: decode_list(tail, [])
    def decode(<<?d, tail :: binary>>), do: decode_dict(tail, %{})
    def decode(data), do: decode_str(data, [])



    #
    # Private functions used for the recursive decoding of the data.  They are type
    # specific and called by the public functions above.
    #
    # All the private decoders work roughly the same way.  If the first character
    # is an 'e' we're at the end of the encoded data for the element.  'acc' will
    # have the string data accumulated up until the 'e', 'tail' will be the
    # remaining, unparsed string data.  We'll pass back the remaining so it can be
    # parsed by another routine/decoder to allow for decoding an entire stream of
    # encoded elements.  Note that since the calls are recursive the accumulator
    # will be reversed from the encoded value.  We'll re-reverse (un-reverse?) it.

    # If we're decoding an integer and the character at the head of the binary is
    # an 'e' we're at the end of the encoded integer.  The match parameter 'tail'
    # will hold everything after the 'e', 'acc' will hold the accumulated characters
    # up to the 'e' - in reversed order due to the recursion.
    defp decode_int(<<?e, tail :: binary>>, acc) do
      valstr = acc
               |> List.to_string   # Turn 'acc' into a string...
               |> String.reverse   # ...and reverse its order

      {String.to_integer(valstr),tail}  # return the extracted integer and the
                                        # remaining binary (for further processing)
    end
    # If we're decoding an integer but did _not_ have an 'e' as the first character,
    # push the first character (here in match parameter 'h') onto the accumulator
    # 'acc' and recursively call 'decode_int' to process what remains.  Eventually
    # we'll hit the 'e' marking the end of the integer and the above function
    # will be called instead of this one...
    defp decode_int(<< h, tail :: binary>>, acc), do: decode_int(tail, [h|acc])

    defp decode_list(<<?e, tail :: binary>>, acc) do
      {Enum.reverse(acc), tail}
    end
    defp decode_list(data, acc) do
      {head, tail} = decode(data)
      decode_list(tail, [head|acc])
    end

    defp decode_dict(<<?e, tail :: binary>>, acc) do
      {acc, tail}
    end
    defp decode_dict(data, acc) do
      {key, tail} = decode(data)
      {val, tail} = decode(tail)
      decode_dict(tail, Map.put(acc, String.to_atom(key), val))
    end

    defp decode_str(<<?:, tail :: binary>>, acc) do
      int = String.to_integer( String.reverse(to_string(acc)) )
      {String.slice(tail, 0..int-1),
       binary_part(tail, int, byte_size(tail)-int)}
    end
    defp decode_str(<< h, tail :: binary>>, acc), do: decode_str(tail, [h|acc])

end
