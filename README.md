<p align="center">
  <img src="https://raw.githubusercontent.com/ljr1981/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_base64

**[Documentation](https://ljr1981.github.io/simple_base64/)**

Lightweight Base64 encoding and decoding library for Eiffel.

## Features

- **Standard Base64** encoding/decoding (RFC 4648)
- **URL-safe Base64URL** variant (for JWT, URLs, filenames)
- **Validation** of Base64 strings
- **Conversion** between standard and URL-safe formats
- **Design by Contract** with full preconditions/postconditions

## Installation

Add to your ECF:

```xml
<library name="simple_base64" location="$SIMPLE_BASE64\simple_base64.ecf"/>
```

Set environment variable:
```
SIMPLE_BASE64=D:\prod\simple_base64
```

## Usage

### Basic Encoding/Decoding

```eiffel
local
    encoder: SIMPLE_BASE64
    encoded, decoded: STRING
do
    create encoder.make

    -- Encode
    encoded := encoder.encode ("Hello, World!")
    -- Result: "SGVsbG8sIFdvcmxkIQ=="

    -- Decode
    decoded := encoder.decode (encoded)
    -- Result: "Hello, World!"
end
```

### URL-Safe Base64URL

```eiffel
local
    encoder: SIMPLE_BASE64
    token: STRING
do
    create encoder.make

    -- URL-safe encoding (no padding, - instead of +, _ instead of /)
    token := encoder.encode_url ("some data")

    -- Decode URL-safe
    decoded := encoder.decode_url (token)
end
```

### Validation

```eiffel
if encoder.is_valid_base64 (some_string) then
    decoded := encoder.decode (some_string)
end
```

### Conversion

```eiffel
-- Convert standard to URL-safe
url_safe := encoder.to_url_safe ("abc+/def==")
-- Result: "abc-_def=="

-- Convert URL-safe to standard
standard := encoder.to_standard ("abc-_def==")
-- Result: "abc+/def=="
```

## API Reference

### Encoding

| Feature | Description |
|---------|-------------|
| `encode (STRING): STRING` | Standard Base64 with padding |
| `encode_bytes (ARRAY[NATURAL_8]): STRING` | Encode raw bytes |
| `encode_url (STRING): STRING` | URL-safe, no padding |
| `encode_url_with_padding (STRING): STRING` | URL-safe with padding |

### Decoding

| Feature | Description |
|---------|-------------|
| `decode (STRING): STRING` | Decode to string (auto-detects format) |
| `decode_bytes (STRING): ARRAY[NATURAL_8]` | Decode to raw bytes |
| `decode_url (STRING): STRING` | Decode URL-safe (alias for decode) |

### Validation

| Feature | Description |
|---------|-------------|
| `is_valid_base64 (STRING): BOOLEAN` | Check standard Base64 validity |
| `is_valid_base64_url (STRING): BOOLEAN` | Check URL-safe validity |

### Conversion

| Feature | Description |
|---------|-------------|
| `to_url_safe (STRING): STRING` | Convert + to -, / to _ |
| `to_standard (STRING): STRING` | Convert - to +, _ to / |

## Use Cases

- **JWT tokens** - Header and payload are Base64URL encoded
- **Data URIs** - `data:image/png;base64,...`
- **HTTP Basic Auth** - `Authorization: Basic <base64>`
- **Email attachments** - MIME Base64 encoding
- **URL parameters** - Safe transmission of binary data

## Dependencies

- EiffelBase only

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
