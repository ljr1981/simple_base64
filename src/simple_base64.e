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
			variant
				Result.count
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

	encode_mime (a_input: STRING): STRING
			-- Encode `a_input' to Base64 with MIME line wrapping.
			-- Lines are wrapped at 76 characters per RFC 2045.
		require
			input_not_void: a_input /= Void
		do
			Result := encode_bytes_mime (string_to_bytes (a_input))
		ensure
			result_not_void: Result /= Void
		end

	encode_bytes_mime (a_bytes: ARRAY [NATURAL_8]): STRING
			-- Encode `a_bytes' to Base64 with MIME line wrapping.
			-- Lines are wrapped at 76 characters per RFC 2045.
		require
			bytes_not_void: a_bytes /= Void
		local
			l_raw: STRING
			i: INTEGER
		do
			l_raw := encode_bytes (a_bytes)
			create Result.make (l_raw.count + (l_raw.count // Mime_line_length) * 2)

			from
				i := 1
			until
				i > l_raw.count
			loop
				if i > 1 and then (i - 1) \\ Mime_line_length = 0 then
					Result.append ("%R%N")
				end
				Result.append_character (l_raw [i])
				i := i + 1
			variant
				l_raw.count - i + 1
			end
		ensure
			result_not_void: Result /= Void
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

	decode_lenient (a_input: STRING): STRING
			-- Decode Base64 `a_input', ignoring whitespace and line breaks.
			-- More tolerant than `decode' - suitable for MIME-encoded content.
		require
			input_not_void: a_input /= Void
		do
			Result := bytes_to_string (decode_bytes_lenient (a_input))
		ensure
			result_not_void: Result /= Void
		end

	decode_bytes_lenient (a_input: STRING): ARRAY [NATURAL_8]
			-- Decode Base64 `a_input' to bytes, ignoring whitespace.
			-- Strips CR, LF, space, and tab before decoding.
		require
			input_not_void: a_input /= Void
		local
			l_cleaned: STRING
			i: INTEGER
			c: CHARACTER
		do
			-- Strip all whitespace
			create l_cleaned.make (a_input.count)
			from
				i := 1
			until
				i > a_input.count
			loop
				c := a_input [i]
				if c /= ' ' and c /= '%T' and c /= '%R' and c /= '%N' then
					l_cleaned.append_character (c)
				end
				i := i + 1
			variant
				a_input.count - i + 1
			end

			Result := decode_bytes (l_cleaned)
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
				variant
					a_input.count - i + 1
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
				variant
					a_input.count - i + 1
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

feature -- Data URI Support

	to_data_uri (a_data, a_mediatype: STRING): STRING
			-- Create a data URI from `a_data' with `a_mediatype'.
			-- Format: data:<mediatype>;base64,<encoded_data>
			-- Example: data:text/plain;base64,SGVsbG8h
		require
			data_not_void: a_data /= Void
			mediatype_not_void: a_mediatype /= Void
			mediatype_not_empty: not a_mediatype.is_empty
		do
			create Result.make (Data_uri_prefix.count + a_mediatype.count + 10 + ((a_data.count + 2) // 3 * 4))
			Result.append (Data_uri_prefix)
			Result.append (a_mediatype)
			Result.append (";base64,")
			Result.append (encode (a_data))
		ensure
			result_not_void: Result /= Void
			is_data_uri: is_data_uri (Result)
		end

	to_data_uri_bytes (a_bytes: ARRAY [NATURAL_8]; a_mediatype: STRING): STRING
			-- Create a data URI from `a_bytes' with `a_mediatype'.
		require
			bytes_not_void: a_bytes /= Void
			mediatype_not_void: a_mediatype /= Void
			mediatype_not_empty: not a_mediatype.is_empty
		do
			create Result.make (Data_uri_prefix.count + a_mediatype.count + 10 + ((a_bytes.count + 2) // 3 * 4))
			Result.append (Data_uri_prefix)
			Result.append (a_mediatype)
			Result.append (";base64,")
			Result.append (encode_bytes (a_bytes))
		ensure
			result_not_void: Result /= Void
			is_data_uri: is_data_uri (Result)
		end

	from_data_uri (a_uri: STRING): STRING
			-- Extract and decode data from `a_uri'.
			-- Returns the decoded data or empty string if invalid.
		require
			uri_not_void: a_uri /= Void
		local
			l_comma_pos: INTEGER
			l_encoded: STRING
		do
			if is_base64_data_uri (a_uri) then
				l_comma_pos := a_uri.index_of (',', 1)
				if l_comma_pos > 0 and l_comma_pos < a_uri.count then
					l_encoded := a_uri.substring (l_comma_pos + 1, a_uri.count)
					Result := decode (l_encoded)
				else
					create Result.make_empty
				end
			else
				create Result.make_empty
			end
		ensure
			result_not_void: Result /= Void
		end

	from_data_uri_bytes (a_uri: STRING): ARRAY [NATURAL_8]
			-- Extract and decode bytes from `a_uri'.
			-- Returns the decoded bytes or empty array if invalid.
		require
			uri_not_void: a_uri /= Void
		local
			l_comma_pos: INTEGER
			l_encoded: STRING
		do
			if is_base64_data_uri (a_uri) then
				l_comma_pos := a_uri.index_of (',', 1)
				if l_comma_pos > 0 and l_comma_pos < a_uri.count then
					l_encoded := a_uri.substring (l_comma_pos + 1, a_uri.count)
					Result := decode_bytes (l_encoded)
				else
					create Result.make_empty
				end
			else
				create Result.make_empty
			end
		ensure
			result_not_void: Result /= Void
		end

	data_uri_mediatype (a_uri: STRING): STRING
			-- Extract the mediatype from `a_uri'.
			-- Returns empty string if not a valid data URI.
		require
			uri_not_void: a_uri /= Void
		local
			l_start, l_end: INTEGER
		do
			if is_data_uri (a_uri) then
				l_start := Data_uri_prefix.count + 1
				-- Find semicolon or comma
				l_end := a_uri.index_of (';', l_start)
				if l_end = 0 then
					l_end := a_uri.index_of (',', l_start)
				end
				if l_end > l_start then
					Result := a_uri.substring (l_start, l_end - 1)
				else
					create Result.make_empty
				end
			else
				create Result.make_empty
			end
		ensure
			result_not_void: Result /= Void
		end

	is_data_uri (a_input: STRING): BOOLEAN
			-- Is `a_input' a valid data URI?
		require
			input_not_void: a_input /= Void
		do
			Result := a_input.starts_with (Data_uri_prefix) and a_input.has (',')
		end

	is_base64_data_uri (a_input: STRING): BOOLEAN
			-- Is `a_input' a Base64-encoded data URI?
		require
			input_not_void: a_input /= Void
		do
			Result := is_data_uri (a_input) and a_input.has_substring (";base64,")
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
			variant
				a_string.count - i + 1
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
			variant
				a_bytes.upper - i + 1
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
				variant
					l_padding_needed
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

	Mime_line_length: INTEGER = 76
			-- Maximum line length for MIME encoding (RFC 2045).

	Data_uri_prefix: STRING = "data:"
			-- Data URI scheme prefix (RFC 2397).

invariant
	standard_alphabet_64: Standard_alphabet.count = 64
	url_safe_alphabet_64: Url_safe_alphabet.count = 64

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
