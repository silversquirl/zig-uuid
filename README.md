# zig-uuid

UUID library for Zig. Currently supports UUID versions 3, 4 and 5.

## Examples

```zig
// Parse a string UUID (can be with or without dashes)
try uuid.Uuid.fromString("00112233-4455-6677-8899-aabbccddeeff")

// Generate a random UUID and format it as a string
uuid.Uuid.v4().toStringCompact();
uuid.Uuid.v4().toStringWithDashes();

// Get the raw bytes of a generated SHA-1 UUID with zero namespace
uuid.Uuid.v5(&uuid.Uuid.zero.bytes, "Hello, world!").bytes;

// Generate an MD5 UUID with custom namespace and convert it to a u128
uuid.Uuid.v3(&namespace.bytes, "foobar").toInt();
```
