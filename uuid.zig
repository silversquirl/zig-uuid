const std = @import("std");
const testing = std.testing;

pub const Uuid = struct {
    bytes: [16]u8,

    pub const zero = Uuid{ .bytes = std.mem.zeroes([16]u8) };

    pub fn v3(ns: []const u8, name: []const u8) Uuid {
        return hashInit(std.crypto.hash.Md5, 3, ns, name);
    }
    pub fn v4() Uuid {
        var v: [16]u8 = undefined;
        std.crypto.random.bytes(&v);
        return init(4, v);
    }
    pub fn v5(ns: []const u8, name: []const u8) Uuid {
        return hashInit(std.crypto.hash.Sha1, 5, ns, name);
    }

    const ParseError = error{ InvalidCharacter, InvalidLength };
    pub fn fromString(str: []const u8) ParseError!Uuid {
        var v: [16]u8 = undefined;
        var i: u64 = 0;
        for (v) |*b| {
            const high = try nextHexDig(str, &i);
            const low = try nextHexDig(str, &i);
            b.* = (high << 4) | low;
        }
        if (i != str.len) {
            return error.InvalidLength;
        }
        return Uuid{ .bytes = v };
    }
    fn nextHexDig(str: []const u8, i: *u64) ParseError!u8 {
        while (i.* < str.len) {
            if (str[i.*] == '-') {
                i.* += 1;
            } else {
                const c = try std.fmt.charToDigit(str[i.*], 16);
                i.* += 1;
                return c;
            }
        }
        return error.InvalidLength;
    }

    pub fn toString(self: Uuid) [36]u8 {
        var buf: [36]u8 = undefined;

        const slice = std.fmt.bufPrint(&buf, "{}-{}-{}-{}-{}", .{
            std.fmt.fmtSliceHexLower(self.bytes[0..4]),
            std.fmt.fmtSliceHexLower(self.bytes[4..6]),
            std.fmt.fmtSliceHexLower(self.bytes[6..8]),
            std.fmt.fmtSliceHexLower(self.bytes[8..10]),
            std.fmt.fmtSliceHexLower(self.bytes[10..16]),
        }) catch unreachable;
        std.debug.assert(slice.len == buf.len);

        return buf;
    }

    pub fn fromInt(n: u128) Uuid {
        var v: [16]u8 = undefined;
        std.mem.writeIntBig(u128, &v, n);
        return Uuid{ .bytes = v };
    }

    pub fn toInt(self: Uuid) u128 {
        return std.mem.readIntBig(u128, &self.bytes);
    }

    fn init(comptime version: u4, bytes: [16]u8) Uuid {
        var v: [16]u8 = bytes;
        v[8] = (v[8] & 0x3f) | 0x80; // Set variant
        v[6] = (v[6] & 0x0f) | (@as(u8, version) << 4); // Set version
        return .{ .bytes = v };
    }

    fn hashInit(comptime Hash: type, comptime version: u4, ns: []const u8, name: []const u8) Uuid {
        var hasher = Hash.init(.{});
        hasher.update(ns);
        hasher.update(name);
        var hashed: [Hash.digest_length]u8 = undefined;
        hasher.final(&hashed);
        return init(version, hashed[0..16].*);
    }

    pub fn format(self: Uuid, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len == 0 or comptime std.mem.eql(u8, fmt, "s")) {
            return std.fmt.formatBuf(&self.toString(), options, writer);
        } else {
            return std.fmt.formatIntValue(self.toInt(), fmt, options, writer);
        }
    }
};

test "UUID v3 generation" {
    const a = Uuid.v3(&Uuid.zero.bytes, "foo bar");
    const b = Uuid.v3(&Uuid.zero.bytes, "foo bar");
    const c = Uuid.v3(&Uuid.zero.bytes, "bar baz");
    const d = Uuid.v3("helloooo", "foo bar");

    try testing.expectEqualSlices(
        u8,
        &(Uuid.fromString("5d686fd9-3ac1-33e2-9493-c2d436bbaee3") catch unreachable).bytes,
        &a.bytes,
    );

    try testing.expectEqualSlices(u8, &a.bytes, &b.bytes);
    try testNotEqual(a, c);
    try testNotEqual(a, d);
}

test "UUID v4 generation" {
    const a = Uuid.v4();
    const b = Uuid.v4();
    try testNotEqual(a, b);
}

test "UUID v5 generation" {
    const a = Uuid.v5(&Uuid.zero.bytes, "foo bar");
    const b = Uuid.v5(&Uuid.zero.bytes, "foo bar");
    const c = Uuid.v5(&Uuid.zero.bytes, "bar baz");
    const d = Uuid.v3(&Uuid.zero.bytes, "foo bar");
    const e = Uuid.v5("hellooooo", "foo bar");

    try testing.expectEqualSlices(
        u8,
        &(Uuid.fromString("963bee72-17fa-5f11-a921-ac4d98f53b5e") catch unreachable).bytes,
        &a.bytes,
    );

    try testing.expectEqualSlices(u8, &a.bytes, &b.bytes);
    try testNotEqual(a, c);
    try testNotEqual(a, d);
    try testNotEqual(a, e);
}

const test_uuid = comptime blk: {
    var buf: [16]u8 = undefined;
    _ = try std.fmt.hexToBytes(&buf, "00112233445566778899aabbccddeeff");
    break :blk Uuid{
        .bytes = buf,
    };
};

test "fromString" {
    const id = try Uuid.fromString("00112233445566778899aabbccddeeff");
    try testing.expectEqualSlices(u8, &test_uuid.bytes, &id.bytes);
    const id2 = try Uuid.fromString("00112233-4455-6677-8899-aabbccddeeff");
    try testing.expectEqualSlices(u8, &test_uuid.bytes, &id2.bytes);
    try testing.expectError(error.InvalidCharacter, Uuid.fromString("00112233+4455-6677-8899-aabbccddeeff"));
    try testing.expectError(error.InvalidLength, Uuid.fromString("00112233-4455-6677-8899-aabbccddeeff0"));
    try testing.expectError(error.InvalidLength, Uuid.fromString("00112233-4455-6677-8899-aabbccddeef"));
}

test "toString" {
    try testing.expectEqualStrings(
        "00112233-4455-6677-8899-aabbccddeeff",
        &test_uuid.toString(),
    );
}

test "fromInt" {
    const id = Uuid.fromInt(0x00112233445566778899aabbccddeeff);
    try testing.expectEqualSlices(u8, &test_uuid.bytes, &id.bytes);
}

test "toInt" {
    const i: u128 = 0x00112233445566778899aabbccddeeff;
    try testing.expectEqual(i, test_uuid.toInt());
}

test "format" {
    try testing.expectFmt("00112233-4455-6677-8899-aabbccddeeff", "{}", .{test_uuid});
    try testing.expectFmt("00112233-4455-6677-8899-aabbccddeeff", "{s}", .{test_uuid});
    try testing.expectFmt("00112233-4455-6677-8899-aabbccddeeff", "{any}", .{test_uuid});
    try testing.expectFmt("00112233445566778899aabbccddeeff", "{x:0>32}", .{test_uuid});
}

fn testNotEqual(a: Uuid, b: Uuid) !void {
    var eql = true;
    for (a.bytes) |ab, i| {
        if (ab != b.bytes[i]) {
            eql = false;
            break;
        }
    }
    try testing.expect(!eql);
}
