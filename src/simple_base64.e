note
	description: "[
		Simple Base64 - Encoding and decoding for Base64 and Base64URL.

		Provides RFC 4648 compliant Base64 encoding and decoding with support for
		both standard Base64 and URL-safe Base64URL variants.

		Features:
		- Encode strings to Base64
		- Decode Base64 to strings
		- URL-safe Base64URL encoding (for JWT, URLs, filenames)
		- Optional padding control

		Usage:
			create encoder.make
			encoded := encoder.encode ("Hello, World!")
			decoded := encoder.decode (encoded)

			-- URL-safe variant
			url_safe := encoder.encode_url ("data+with/special=chars")
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=Documentation", "src=../docs/index.html", "protocol=URI", "tag=documentation"
	EIS: "name=API Reference", "src=../docs/api/simple_base64.html", "protocol=URI", "tag=api"
	EIS: "name=RFC 4648", "src=https://datatracker.ietf.org/doc/html/rfc4648", "protocol=URI", "tag=specification"

class
	SIMPLE_BASE64

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize the encoder.
		do
			-- Nothing to initialize, all constants
		end

feature -- Encoding

	encode (a_input: STRING): STRING
			-- Encode `a_input' to standard Base64.
		require
			input_not_void: a_input /= Void
		do
			Result := encode_bytes (string_to_bytes (a_input))
		ensure
			result_not_void: Result /= Void
			valid_base64: is_valid_base64 (Result)
		end

	encode_bytes (a_bytes: ARRAY [NATURAL_8]): STRING
			-- Encode `a_bytes' to standard Base64.
		require
			bytes_not_void: a_bytes /= Void
		local
			i, n: INTEGER
			b1, b2, b3: NATURAL_8
			c1, c2, c3, c4: INTEGER
		do
			n := a_bytes.count
			create Result.make ((n + 2) // 3 * 4)

			from
				i := a_bytes.lower
			until
				i > n + a_bytes.lower - 1
			loop
				-- Get up to 3 bytes
				b1 := a_bytes [i]
				if i + 1 <= n + a_bytes.lower - 1 then
					b2 := a_bytes [i + 1]
				else
					b2 := 0
				end
				if i + 2 <= n + a_bytes.lower - 1 then
					b3 := a_bytes [i + 2]
				else
					b3 := 0
				end

				-- Convert to 4 6-bit values
				c1 := (b1 |>> 2).to_integer_32
				c2 := (((b1 & 0x03) |<< 4) | (b2 |>> 4)).to_integer_32
				c3 := (((b2 & 0x0F) |<< 2) | (b3 |>> 6)).to_integer_32
				c4 := (b3 & 0x3F).to_integer_32

				-- Encode to characters
				Result.append_character (Standard_alphabet [c1 + 1])
				Result.append_character (Standard_alphabet [c2 + 1])

				if i + 1 <= n + a_bytes.lower - 1 then
					Result.append_character (Standard_alphabet [c3 + 1])
				else
					Result.append_character (Padding_char)
				end

				if i + 2 <= n + a_bytes.lower - 1 then
					Result.append_character (Standard_alphabet [c4 + 1])
				else
					Result.append_character (Padding_char)
				end

				i := i + 3
			variant
				n - i + a_bytes.lower + 2
			end
		ensure
			result_not_void: Result /= Void
			correct_length: Result.count = ((a_bytes.count + 2) // 3 * 4)
		end

	encode_url (a_input: STRING): STRING
			-- Encode `a_input' to URL-safe Base64URL (no padding).
		require
			input_not_void: a_input /= Void
		do
			Result := encode (a_input)
			Result := to_url_safe (Result)
			-- Remove padding for URL-safe
			from
			until
				Result.is_empty or else Result [Result.count] /= '='
			loop
				Result.remove_tail (1)
			end
		ensure
			result_not_void: Result /= Void
			no_padding: not Result.has ('=')
			url_safe: not Result.has ('+') and not Result.has ('/')
		end

	encode_url_with_padding (a_input: STRING): STRING
			-- Encode `a_input' to URL-safe Base64URL (with padding).
		require
			input_not_void: a_input /= Void
		do
			Result := encode (a_input)
			Result := to_url_safe (Result)
		ensure
			result_not_void: Result /= Void
			url_safe: not Result.has ('+') and not Result.has ('/')
		end

feature -- Decoding

	decode (a_input: STRING): STRING
			-- Decode standard Base64 `a_input' to string.
		require
			input_not_void: a_input /= Void
			valid_input: is_valid_base64 (a_input) or is_valid_base64_url (a_input)
		do
			Result := bytes_to_string (decode_bytes (a_input))
		ensure
			result_not_void: Result /= Void
		end

	decode_bytes (a_input: STRING): ARRAY [NATURAL_8]
			-- Decode Base64 `a_input' to bytes.
		require
			input_not_void: a_input /= Void
			valid_or_normalizable: is_valid_base64 (a_input) or is_valid_base64_url (a_input) or a_input.is_empty
		local
			l_input: STRING
			i, n: INTEGER
			c1, c2, c3, c4: INTEGER
			b1, b2, b3: NATURAL_8
			l_bytes: ARRAYED_LIST [NATURAL_8]
			padding_count: INTEGER
		do
			-- Normalize: convert URL-safe to standard, add padding if needed
			l_input := normalize_input (a_input)
			n := l_input.count

			-- Count padding
			if n >= 1 and then l_input [n] = '=' then
				padding_count := 1
				if n >= 2 and then l_input [n - 1] = '=' then
					padding_count := 2
				end
			end

			create l_bytes.make ((n // 4) * 3)

			from
				i := 1
			until
				i > n
			loop
				-- Get 4 characters
				c1 := char_to_value (l_input [i])
				c2 := char_to_value (l_input [i + 1])
				if l_input [i + 2] /= '=' then
					c3 := char_to_value (l_input [i + 2])
				else
					c3 := 0
				end
				if l_input [i + 3] /= '=' then
					c4 := char_to_value (l_input [i + 3])
				else
					c4 := 0
				end

				-- Convert to 3 bytes
				b1 := ((c1 |<< 2) | (c2 |>> 4)).to_natural_8
				b2 := (((c2 & 0x0F) |<< 4) | (c3 |>> 2)).to_natural_8
				b3 := (((c3 & 0x03) |<< 6) | c4).to_natural_8

				l_bytes.extend (b1)
				if l_input [i + 2] /= '=' then
					l_bytes.extend (b2)
				end
				if l_input [i + 3] /= '=' then
					l_bytes.extend (b3)
				end

				i := i + 4
			variant
				n - i + 4
			end

			create Result.make_from_array (l_bytes.to_array)
		ensure
			result_not_void: Result /= Void
		end

	decode_url (a_input: STRING): STRING
			-- Decode URL-safe Base64URL `a_input' to string.
		require
			input_not_void: a_input /= Void
		do
			Result := decode (a_input)
		ensure
			result_not_void: Result /= Void
		end

feature -- Validation

	is_valid_base64 (a_input: STRING): BOOLEAN
			-- Is `a_input' valid standard Base64?
		require
			input_not_void: a_input /= Void
		local
			i: INTEGER
			c: CHARACTER
			padding_started: BOOLEAN
		do
			if a_input.is_empty then
				Result := True
			elseif a_input.count \\ 4 /= 0 then
				Result := False
			else
				Result := True
				from
					i := 1
				until
					i > a_input.count or not Result
				loop
					c := a_input [i]
					if c = '=' then
						padding_started := True
					elseif padding_started then
						-- No characters allowed after padding
						Result := False
					elseif not Standard_alphabet.has (c) then
						Result := False
					end
					i := i + 1
				end
			end
		end

	is_valid_base64_url (a_input: STRING): BOOLEAN
			-- Is `a_input' valid URL-safe Base64URL?
		require
			input_not_void: a_input /= Void
		local
			i: INTEGER
			c: CHARACTER
		do
			if a_input.is_empty then
				Result := True
			else
				Result := True
				from
					i := 1
				until
					i > a_input.count or not Result
				loop
					c := a_input [i]
					if not Url_safe_alphabet.has (c) and c /= '=' then
						Result := False
					end
					i := i + 1
				end
			end
		end

feature -- Conversion

	to_url_safe (a_base64: STRING): STRING
			-- Convert standard Base64 to URL-safe Base64URL.
		require
			input_not_void: a_base64 /= Void
		do
			Result := a_base64.twin
			Result.replace_substring_all ("+", "-")
			Result.replace_substring_all ("/", "_")
		ensure
			result_not_void: Result /= Void
			no_plus: not Result.has ('+')
			no_slash: not Result.has ('/')
		end

	to_standard (a_base64url: STRING): STRING
			-- Convert URL-safe Base64URL to standard Base64.
		require
			input_not_void: a_base64url /= Void
		do
			Result := a_base64url.twin
			Result.replace_substring_all ("-", "+")
			Result.replace_substring_all ("_", "/")
		ensure
			result_not_void: Result /= Void
			no_dash: not Result.has ('-')
			no_underscore: not Result.has ('_')
		end

feature {NONE} -- Implementation

	string_to_bytes (a_string: STRING): ARRAY [NATURAL_8]
			-- Convert `a_string' to byte array.
		require
			string_not_void: a_string /= Void
		local
			i: INTEGER
			l_bytes: ARRAYED_LIST [NATURAL_8]
		do
			create l_bytes.make (a_string.count)
			from
				i := 1
			until
				i > a_string.count
			loop
				l_bytes.extend (a_string [i].code.to_natural_8)
				i := i + 1
			end
			create Result.make_from_array (l_bytes.to_array)
		ensure
			result_not_void: Result /= Void
			same_count: Result.count = a_string.count
		end

	bytes_to_string (a_bytes: ARRAY [NATURAL_8]): STRING
			-- Convert `a_bytes' to string.
		require
			bytes_not_void: a_bytes /= Void
		local
			i: INTEGER
		do
			create Result.make (a_bytes.count)
			from
				i := a_bytes.lower
			until
				i > a_bytes.upper
			loop
				Result.append_character (a_bytes [i].to_character_8)
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
			same_count: Result.count = a_bytes.count
		end

	char_to_value (a_char: CHARACTER): INTEGER
			-- Convert Base64 character to 6-bit value.
		require
			valid_base64_char: Standard_alphabet.has (a_char) or Url_safe_alphabet.has (a_char) or a_char = '='
		local
			l_pos: INTEGER
		do
			l_pos := Standard_alphabet.index_of (a_char, 1)
			if l_pos > 0 then
				Result := l_pos - 1
			else
				-- Try URL-safe
				l_pos := Url_safe_alphabet.index_of (a_char, 1)
				if l_pos > 0 then
					Result := l_pos - 1
				else
					Result := 0
				end
			end
		ensure
			valid_range: Result >= 0 and Result <= 63
		end

	normalize_input (a_input: STRING): STRING
			-- Normalize `a_input': convert URL-safe to standard, add padding.
		require
			input_not_void: a_input /= Void
		local
			l_padding_needed: INTEGER
		do
			-- Convert to standard alphabet
			Result := to_standard (a_input)

			-- Add padding if needed
			if Result.count > 0 then
				l_padding_needed := (4 - (Result.count \\ 4)) \\ 4
				from
				until
					l_padding_needed = 0
				loop
					Result.append_character ('=')
					l_padding_needed := l_padding_needed - 1
				end
			end
		ensure
			result_not_void: Result /= Void
			padded: Result.count \\ 4 = 0
		end

feature -- Constants

	Standard_alphabet: STRING = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			-- Standard Base64 alphabet (RFC 4648).

	Url_safe_alphabet: STRING = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
			-- URL-safe Base64URL alphabet (RFC 4648).

	Padding_char: CHARACTER = '='
			-- Padding character.

invariant
	standard_alphabet_64: Standard_alphabet.count = 64
	url_safe_alphabet_64: Url_safe_alphabet.count = 64

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
