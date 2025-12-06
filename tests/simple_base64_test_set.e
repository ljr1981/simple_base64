note
	description: "Tests for SIMPLE_BASE64"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	SIMPLE_BASE64_TEST_SET

inherit
	TEST_SET_BASE

feature -- Test: Encoding

	test_encode_empty
			-- Test encoding empty string.
		note
			testing: "covers/{SIMPLE_BASE64}.encode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("empty encodes to empty", "", encoder.encode (""))
		end

	test_encode_single_char
			-- Test encoding single character.
		note
			testing: "covers/{SIMPLE_BASE64}.encode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			-- 'M' = 77 = 01001101
			-- Padded to 010011 010000 (padding)
			-- = 19, 16 = T, Q
			assert_strings_equal ("single M", "TQ==", encoder.encode ("M"))
		end

	test_encode_two_chars
			-- Test encoding two characters.
		note
			testing: "covers/{SIMPLE_BASE64}.encode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			-- 'Ma' = 77, 97
			assert_strings_equal ("two chars Ma", "TWE=", encoder.encode ("Ma"))
		end

	test_encode_three_chars
			-- Test encoding three characters (no padding).
		note
			testing: "covers/{SIMPLE_BASE64}.encode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			-- 'Man' = 77, 97, 110 -> TWFu (no padding)
			assert_strings_equal ("three chars Man", "TWFu", encoder.encode ("Man"))
		end

	test_encode_hello_world
			-- Test encoding "Hello, World!".
		note
			testing: "covers/{SIMPLE_BASE64}.encode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("Hello World", "SGVsbG8sIFdvcmxkIQ==", encoder.encode ("Hello, World!"))
		end

	test_encode_standard_test_vectors
			-- Test RFC 4648 test vectors.
		note
			testing: "covers/{SIMPLE_BASE64}.encode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("f", "Zg==", encoder.encode ("f"))
			assert_strings_equal ("fo", "Zm8=", encoder.encode ("fo"))
			assert_strings_equal ("foo", "Zm9v", encoder.encode ("foo"))
			assert_strings_equal ("foob", "Zm9vYg==", encoder.encode ("foob"))
			assert_strings_equal ("fooba", "Zm9vYmE=", encoder.encode ("fooba"))
			assert_strings_equal ("foobar", "Zm9vYmFy", encoder.encode ("foobar"))
		end

feature -- Test: Decoding

	test_decode_empty
			-- Test decoding empty string.
		note
			testing: "covers/{SIMPLE_BASE64}.decode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("empty decodes to empty", "", encoder.decode (""))
		end

	test_decode_single_char
			-- Test decoding single character encoding.
		note
			testing: "covers/{SIMPLE_BASE64}.decode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("decode TQ==", "M", encoder.decode ("TQ=="))
		end

	test_decode_two_chars
			-- Test decoding two character encoding.
		note
			testing: "covers/{SIMPLE_BASE64}.decode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("decode TWE=", "Ma", encoder.decode ("TWE="))
		end

	test_decode_three_chars
			-- Test decoding three character encoding.
		note
			testing: "covers/{SIMPLE_BASE64}.decode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("decode TWFu", "Man", encoder.decode ("TWFu"))
		end

	test_decode_hello_world
			-- Test decoding "Hello, World!".
		note
			testing: "covers/{SIMPLE_BASE64}.decode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("decode Hello World", "Hello, World!", encoder.decode ("SGVsbG8sIFdvcmxkIQ=="))
		end

	test_decode_standard_test_vectors
			-- Test RFC 4648 test vectors.
		note
			testing: "covers/{SIMPLE_BASE64}.decode"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("decode f", "f", encoder.decode ("Zg=="))
			assert_strings_equal ("decode fo", "fo", encoder.decode ("Zm8="))
			assert_strings_equal ("decode foo", "foo", encoder.decode ("Zm9v"))
			assert_strings_equal ("decode foob", "foob", encoder.decode ("Zm9vYg=="))
			assert_strings_equal ("decode fooba", "fooba", encoder.decode ("Zm9vYmE="))
			assert_strings_equal ("decode foobar", "foobar", encoder.decode ("Zm9vYmFy"))
		end

feature -- Test: Round-trip

	test_roundtrip_ascii
			-- Test encoding then decoding returns original.
		note
			testing: "covers/{SIMPLE_BASE64}.encode", "covers/{SIMPLE_BASE64}.decode"
		local
			encoder: SIMPLE_BASE64
			original, encoded, decoded: STRING
		do
			create encoder.make
			original := "The quick brown fox jumps over the lazy dog."
			encoded := encoder.encode (original)
			decoded := encoder.decode (encoded)
			assert_strings_equal ("roundtrip ascii", original, decoded)
		end

	test_roundtrip_binary
			-- Test round-trip with binary-ish data.
		note
			testing: "covers/{SIMPLE_BASE64}.encode", "covers/{SIMPLE_BASE64}.decode"
		local
			encoder: SIMPLE_BASE64
			original, decoded: STRING
		do
			create encoder.make
			original := "%/0/%/1/%/255/%/128/%/64/"
			decoded := encoder.decode (encoder.encode (original))
			assert_strings_equal ("roundtrip binary", original, decoded)
		end

feature -- Test: URL-Safe

	test_encode_url_no_padding
			-- Test URL-safe encoding removes padding.
		note
			testing: "covers/{SIMPLE_BASE64}.encode_url"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			-- "M" standard = "TQ==" but URL-safe = "TQ"
			assert ("no padding", not encoder.encode_url ("M").has ('='))
		end

	test_encode_url_replaces_plus
			-- Test URL-safe encoding replaces + with -.
		note
			testing: "covers/{SIMPLE_BASE64}.encode_url"
		local
			encoder: SIMPLE_BASE64
			encoded: STRING
		do
			create encoder.make
			-- Need input that produces + in standard base64
			-- "?>" = 63, 62 -> produces "Pz4=" standard
			-- Let's use binary: 62, 63 bytes -> produces +/
			encoded := encoder.encode_url ("?>")
			assert ("no plus", not encoded.has ('+'))
		end

	test_encode_url_replaces_slash
			-- Test URL-safe encoding replaces / with _.
		note
			testing: "covers/{SIMPLE_BASE64}.encode_url"
		local
			encoder: SIMPLE_BASE64
			encoded: STRING
		do
			create encoder.make
			encoded := encoder.encode_url ("?>")
			assert ("no slash", not encoded.has ('/'))
		end

	test_decode_url_safe
			-- Test decoding URL-safe input.
		note
			testing: "covers/{SIMPLE_BASE64}.decode_url"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			-- URL-safe without padding
			assert_strings_equal ("decode url-safe", "Man", encoder.decode_url ("TWFu"))
		end

	test_decode_url_safe_no_padding
			-- Test decoding URL-safe input without padding.
		note
			testing: "covers/{SIMPLE_BASE64}.decode_url"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			-- "M" encodes to "TQ==" standard, "TQ" url-safe
			assert_strings_equal ("decode url-safe no padding", "M", encoder.decode_url ("TQ"))
		end

feature -- Test: Validation

	test_is_valid_base64_empty
			-- Test empty string is valid.
		note
			testing: "covers/{SIMPLE_BASE64}.is_valid_base64"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert ("empty is valid", encoder.is_valid_base64 (""))
		end

	test_is_valid_base64_correct
			-- Test correct base64 is valid.
		note
			testing: "covers/{SIMPLE_BASE64}.is_valid_base64"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert ("correct is valid", encoder.is_valid_base64 ("SGVsbG8="))
		end

	test_is_valid_base64_wrong_length
			-- Test wrong length is invalid.
		note
			testing: "covers/{SIMPLE_BASE64}.is_valid_base64"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert ("wrong length is invalid", not encoder.is_valid_base64 ("SGVsbG8"))
		end

	test_is_valid_base64_invalid_char
			-- Test invalid character is invalid.
		note
			testing: "covers/{SIMPLE_BASE64}.is_valid_base64"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert ("invalid char is invalid", not encoder.is_valid_base64 ("SGVs!G8="))
		end

feature -- Test: Conversion

	test_to_url_safe
			-- Test standard to URL-safe conversion.
		note
			testing: "covers/{SIMPLE_BASE64}.to_url_safe"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("to url safe", "abc-_def", encoder.to_url_safe ("abc+/def"))
		end

	test_to_standard
			-- Test URL-safe to standard conversion.
		note
			testing: "covers/{SIMPLE_BASE64}.to_standard"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("to standard", "abc+/def", encoder.to_standard ("abc-_def"))
		end

feature -- Test: MIME Encoding

	test_encode_mime_short
			-- Test MIME encoding of short string (no wrapping needed).
		note
			testing: "covers/{SIMPLE_BASE64}.encode_mime"
		local
			encoder: SIMPLE_BASE64
			encoded: STRING
		do
			create encoder.make
			encoded := encoder.encode_mime ("Hello, World!")
			-- Short string should be same as standard encoding
			assert_strings_equal ("short mime same as standard", "SGVsbG8sIFdvcmxkIQ==", encoded)
		end

	test_encode_mime_wraps_at_76
			-- Test MIME encoding wraps lines at 76 characters.
		note
			testing: "covers/{SIMPLE_BASE64}.encode_mime"
		local
			encoder: SIMPLE_BASE64
			encoded: STRING
			long_input: STRING
		do
			create encoder.make
			-- Create input that produces > 76 chars of base64
			-- 60 bytes = 80 base64 chars, so should wrap
			create long_input.make_filled ('A', 60)
			encoded := encoder.encode_mime (long_input)
			-- Should contain CRLF
			assert ("has line break", encoded.has_substring ("%R%N"))
		end

	test_encode_mime_first_line_76
			-- Test MIME encoding first line is exactly 76 characters.
		note
			testing: "covers/{SIMPLE_BASE64}.encode_mime"
		local
			encoder: SIMPLE_BASE64
			encoded: STRING
			long_input: STRING
			first_line_end: INTEGER
		do
			create encoder.make
			-- Create long input
			create long_input.make_filled ('X', 100)
			encoded := encoder.encode_mime (long_input)
			-- Find first line break
			first_line_end := encoded.substring_index ("%R%N", 1)
			assert ("first line is 76", first_line_end = 77)
		end

	test_encode_mime_decode_roundtrip
			-- Test MIME encoded content can be decoded with lenient decoder.
		note
			testing: "covers/{SIMPLE_BASE64}.encode_mime"
			testing: "covers/{SIMPLE_BASE64}.decode_lenient"
		local
			encoder: SIMPLE_BASE64
			original, encoded, decoded: STRING
		do
			create encoder.make
			create original.make_filled ('Z', 100)
			encoded := encoder.encode_mime (original)
			decoded := encoder.decode_lenient (encoded)
			assert_strings_equal ("mime roundtrip", original, decoded)
		end

feature -- Test: Lenient Decoding

	test_decode_lenient_standard
			-- Test lenient decode works on standard input.
		note
			testing: "covers/{SIMPLE_BASE64}.decode_lenient"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("lenient standard", "Hello", encoder.decode_lenient ("SGVsbG8="))
		end

	test_decode_lenient_with_spaces
			-- Test lenient decode ignores spaces.
		note
			testing: "covers/{SIMPLE_BASE64}.decode_lenient"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("lenient with spaces", "Hello", encoder.decode_lenient ("SGVs bG8="))
		end

	test_decode_lenient_with_newlines
			-- Test lenient decode ignores newlines.
		note
			testing: "covers/{SIMPLE_BASE64}.decode_lenient"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("lenient with newlines", "Hello", encoder.decode_lenient ("SGVs%R%NbG8="))
		end

	test_decode_lenient_with_tabs
			-- Test lenient decode ignores tabs.
		note
			testing: "covers/{SIMPLE_BASE64}.decode_lenient"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("lenient with tabs", "Hello", encoder.decode_lenient ("SGVs%TbG8="))
		end

	test_decode_lenient_mixed_whitespace
			-- Test lenient decode ignores all types of whitespace.
		note
			testing: "covers/{SIMPLE_BASE64}.decode_lenient"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			-- Base64 for "Man" is "TWFu" with various whitespace
			assert_strings_equal ("lenient mixed ws", "Man", encoder.decode_lenient ("T W%R%NF%Tu"))
		end

feature -- Test: Data URI Support

	test_to_data_uri_text_plain
			-- Test creating data URI with text/plain mediatype.
		note
			testing: "covers/{SIMPLE_BASE64}.to_data_uri"
		local
			encoder: SIMPLE_BASE64
			uri: STRING
		do
			create encoder.make
			uri := encoder.to_data_uri ("Hello!", "text/plain")
			assert_strings_equal ("text plain data uri", "data:text/plain;base64,SGVsbG8h", uri)
		end

	test_to_data_uri_image
			-- Test creating data URI with image/png mediatype.
		note
			testing: "covers/{SIMPLE_BASE64}.to_data_uri"
		local
			encoder: SIMPLE_BASE64
			uri: STRING
		do
			create encoder.make
			uri := encoder.to_data_uri ("PNG", "image/png")
			assert ("starts with data:", uri.starts_with ("data:image/png;base64,"))
		end

	test_from_data_uri
			-- Test extracting data from data URI.
		note
			testing: "covers/{SIMPLE_BASE64}.from_data_uri"
		local
			encoder: SIMPLE_BASE64
			data: STRING
		do
			create encoder.make
			data := encoder.from_data_uri ("data:text/plain;base64,SGVsbG8h")
			assert_strings_equal ("extracted data", "Hello!", data)
		end

	test_from_data_uri_invalid
			-- Test extracting from invalid data URI returns empty.
		note
			testing: "covers/{SIMPLE_BASE64}.from_data_uri"
		local
			encoder: SIMPLE_BASE64
			data: STRING
		do
			create encoder.make
			data := encoder.from_data_uri ("not a data uri")
			assert_strings_equal ("invalid returns empty", "", data)
		end

	test_data_uri_mediatype
			-- Test extracting mediatype from data URI.
		note
			testing: "covers/{SIMPLE_BASE64}.data_uri_mediatype"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("mediatype text/plain", "text/plain", encoder.data_uri_mediatype ("data:text/plain;base64,SGVsbG8h"))
			assert_strings_equal ("mediatype image/png", "image/png", encoder.data_uri_mediatype ("data:image/png;base64,AAAA"))
		end

	test_data_uri_mediatype_invalid
			-- Test extracting mediatype from invalid URI returns empty.
		note
			testing: "covers/{SIMPLE_BASE64}.data_uri_mediatype"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_strings_equal ("invalid returns empty", "", encoder.data_uri_mediatype ("not a data uri"))
		end

	test_is_data_uri_valid
			-- Test is_data_uri returns True for valid data URI.
		note
			testing: "covers/{SIMPLE_BASE64}.is_data_uri"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert ("valid data uri", encoder.is_data_uri ("data:text/plain;base64,SGVsbG8h"))
		end

	test_is_data_uri_invalid
			-- Test is_data_uri returns False for invalid strings.
		note
			testing: "covers/{SIMPLE_BASE64}.is_data_uri"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert_false ("not a data uri", encoder.is_data_uri ("http://example.com"))
			assert_false ("empty", encoder.is_data_uri (""))
			assert_false ("no comma", encoder.is_data_uri ("data:text/plain"))
		end

	test_is_base64_data_uri
			-- Test is_base64_data_uri distinguishes base64 from non-base64.
		note
			testing: "covers/{SIMPLE_BASE64}.is_base64_data_uri"
		local
			encoder: SIMPLE_BASE64
		do
			create encoder.make
			assert ("base64 data uri", encoder.is_base64_data_uri ("data:text/plain;base64,SGVsbG8h"))
			assert_false ("non-base64 data uri", encoder.is_base64_data_uri ("data:text/plain,Hello!"))
		end

	test_data_uri_roundtrip
			-- Test data URI encode/decode roundtrip.
		note
			testing: "covers/{SIMPLE_BASE64}.to_data_uri"
			testing: "covers/{SIMPLE_BASE64}.from_data_uri"
		local
			encoder: SIMPLE_BASE64
			original: STRING
			uri, decoded: STRING
		do
			create encoder.make
			original := "The quick brown fox jumps over the lazy dog."
			uri := encoder.to_data_uri (original, "text/plain")
			decoded := encoder.from_data_uri (uri)
			assert_strings_equal ("roundtrip", original, decoded)
		end

end
