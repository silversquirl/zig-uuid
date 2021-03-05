# zig-uuid

UUID library for Zig. Currently supports UUID versions 3, 4 and 5.

## Examples

```zig
// Parse a string UUID (can be with or without dashes)
try uuid.Uuid.fromString("00112233-4455-6677-8899-aabbccddeeff")

// Generate a random UUID and format it as a string
uuid.Uuid.v4().toString();

// Get the raw bytes of a generated SHA-1 UUID
uuid.Uuid.v5(uuid.Uuid.zero, "Hello, world!").bytes;

// Generate an MD5 UUID and convert it to a u128
uuid.Uuid.v3(uuid.Uuid.zero, "foobar").toInt();
```
