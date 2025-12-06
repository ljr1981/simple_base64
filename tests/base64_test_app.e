note
	description: "Test application for simple_base64"
	author: "Larry Rix"

class
	BASE64_TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		local
			tests: SIMPLE_BASE64_TEST_SET
		do
			create tests
			print ("simple_base64 test runner%N")
			print ("========================%N%N")

			passed := 0
			failed := 0

			-- Encoding
			run_test (agent tests.test_encode_empty, "test_encode_empty")
			run_test (agent tests.test_encode_single_char, "test_encode_single_char")
			run_test (agent tests.test_encode_two_chars, "test_encode_two_chars")
			run_test (agent tests.test_encode_three_chars, "test_encode_three_chars")
			run_test (agent tests.test_encode_hello_world, "test_encode_hello_world")
			run_test (agent tests.test_encode_standard_test_vectors, "test_encode_standard_test_vectors")

			-- Decoding
			run_test (agent tests.test_decode_empty, "test_decode_empty")
			run_test (agent tests.test_decode_single_char, "test_decode_single_char")
			run_test (agent tests.test_decode_two_chars, "test_decode_two_chars")
			run_test (agent tests.test_decode_three_chars, "test_decode_three_chars")
			run_test (agent tests.test_decode_hello_world, "test_decode_hello_world")
			run_test (agent tests.test_decode_standard_test_vectors, "test_decode_standard_test_vectors")

			-- Round-trip
			run_test (agent tests.test_roundtrip_ascii, "test_roundtrip_ascii")
			run_test (agent tests.test_roundtrip_binary, "test_roundtrip_binary")

			-- URL-Safe
			run_test (agent tests.test_encode_url_no_padding, "test_encode_url_no_padding")
			run_test (agent tests.test_encode_url_replaces_plus, "test_encode_url_replaces_plus")
			run_test (agent tests.test_encode_url_replaces_slash, "test_encode_url_replaces_slash")
			run_test (agent tests.test_decode_url_safe, "test_decode_url_safe")
			run_test (agent tests.test_decode_url_safe_no_padding, "test_decode_url_safe_no_padding")

			-- Validation
			run_test (agent tests.test_is_valid_base64_empty, "test_is_valid_base64_empty")
			run_test (agent tests.test_is_valid_base64_correct, "test_is_valid_base64_correct")
			run_test (agent tests.test_is_valid_base64_wrong_length, "test_is_valid_base64_wrong_length")
			run_test (agent tests.test_is_valid_base64_invalid_char, "test_is_valid_base64_invalid_char")

			-- Conversion
			run_test (agent tests.test_to_url_safe, "test_to_url_safe")
			run_test (agent tests.test_to_standard, "test_to_standard")

			-- MIME Encoding
			run_test (agent tests.test_encode_mime_short, "test_encode_mime_short")
			run_test (agent tests.test_encode_mime_wraps_at_76, "test_encode_mime_wraps_at_76")
			run_test (agent tests.test_encode_mime_first_line_76, "test_encode_mime_first_line_76")
			run_test (agent tests.test_encode_mime_decode_roundtrip, "test_encode_mime_decode_roundtrip")

			-- Lenient Decoding
			run_test (agent tests.test_decode_lenient_standard, "test_decode_lenient_standard")
			run_test (agent tests.test_decode_lenient_with_spaces, "test_decode_lenient_with_spaces")
			run_test (agent tests.test_decode_lenient_with_newlines, "test_decode_lenient_with_newlines")
			run_test (agent tests.test_decode_lenient_with_tabs, "test_decode_lenient_with_tabs")
			run_test (agent tests.test_decode_lenient_mixed_whitespace, "test_decode_lenient_mixed_whitespace")

			-- Data URI Support
			run_test (agent tests.test_to_data_uri_text_plain, "test_to_data_uri_text_plain")
			run_test (agent tests.test_to_data_uri_image, "test_to_data_uri_image")
			run_test (agent tests.test_from_data_uri, "test_from_data_uri")
			run_test (agent tests.test_from_data_uri_invalid, "test_from_data_uri_invalid")
			run_test (agent tests.test_data_uri_mediatype, "test_data_uri_mediatype")
			run_test (agent tests.test_data_uri_mediatype_invalid, "test_data_uri_mediatype_invalid")
			run_test (agent tests.test_is_data_uri_valid, "test_is_data_uri_valid")
			run_test (agent tests.test_is_data_uri_invalid, "test_is_data_uri_invalid")
			run_test (agent tests.test_is_base64_data_uri, "test_is_base64_data_uri")
			run_test (agent tests.test_data_uri_roundtrip, "test_data_uri_roundtrip")

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
