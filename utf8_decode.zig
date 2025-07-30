const std = @import("std");

pub fn decodeUtf8(bytes: []const u8) !u21 {
    return switch (bytes.len) {
        1 => @as(u21, bytes[0]),
        2 => decodeUtf8Len2(bytes),
        3 => decodeUtf8Len3(bytes),
        4 => decodeUtf8Len4(bytes),
        else => unreachable,
    };
}

fn decodeUtf8Len2(bytes: []const u8) !u21 {
    std.debug.assert(bytes.len == 2);
    std.debug.assert(bytes[0] & 0b11100000 == 0b11000000);
    std.debug.assert(bytes[1] & 0b11000000 == 0b10000000);

    var decoded: u21 = bytes[0] & 0b00011111;
    decoded <<= 6;
    decoded |= bytes[1] & 0b00111111;
    return decoded;
}

fn decodeUtf8Len3(bytes: []const u8) !u21 {
    std.debug.assert(bytes.len == 3);
    std.debug.assert(bytes[0] & 0b11110000 == 0b11100000);
    std.debug.assert(bytes[1] & 0b11000000 == 0b10000000);
    std.debug.assert(bytes[2] & 0b11000000 == 0b10000000);

    var decoded: u21 = bytes[0] & 0b00001111;
    decoded <<= 6;
    decoded |= bytes[1] & 0b00111111;
    decoded <<= 6;
    decoded |= bytes[2] & 0b00111111;

    return decoded;
}

fn decodeUtf8Len4(bytes: []const u8) !u21 {
    std.debug.assert(bytes.len == 4);
    std.debug.assert(bytes[0] & 0b11111000 == 0b11110000);
    std.debug.assert(bytes[1] & 0b11000000 == 0b10000000);
    std.debug.assert(bytes[2] & 0b11000000 == 0b10000000);
    std.debug.assert(bytes[3] & 0b11000000 == 0b10000000);

    var decoded: u21 = bytes[0] & 0b00001111;
    decoded <<= 6;
    decoded |= bytes[1] & 0b00111111;
    decoded <<= 6;
    decoded |= bytes[2] & 0b00111111;
    decoded <<= 6;
    decoded |= bytes[3] & 0b00111111;

    return decoded;
}

/// firstByte: first byte of UTF-8 codepoint
/// Returns: range of 1~4 indicating total length of UTF-8 codepoint in bytes
pub fn getUtf8BytesLength(first_byte: u8) !u3 {
    if (first_byte & 0b10000000 == 0b00000000) { // 0b0xxxxxxx
        return 1;
    } else if (first_byte & 0b11100000 == 0b11000000) { // 0b110xxxxx
        return 2;
    } else if (first_byte & 0b11110000 == 0b11100000) { // 0b1110xxxx
        return 3;
    } else if (first_byte & 0b11111000 == 0b11110000) { // 0b11110xxx
        return 4;
    } else {
        unreachable;
    }
}

pub const Utf8View = struct {
    str: []const u8,
    cur: u32 = 0,
    pub fn init(str: []const u8) Utf8View {
        return Utf8View{ .str = str };
    }

    pub fn next(self: *Utf8View) ?Utf8Codepoint {
        if (self.cur == self.str.len) return null;

        const len = try getUtf8BytesLength(self.str[self.cur]);
        const unicodepoint = Utf8Codepoint.initFromBytes(self.str[self.cur .. self.cur + len]);
        self.cur = self.cur + len;
        return unicodepoint;
    }
};

pub const Utf8Codepoint = struct {
    code: u21,
    bytes: []const u8,

    pub fn initFromBytes(bytes: []const u8) Utf8Codepoint {
        return Utf8Codepoint{
            .code = try decodeUtf8(bytes),
            .bytes = bytes,
        };
    }

    pub fn hexRepresentation(self: Utf8Codepoint, allocator: std.mem.Allocator) ![]const u8 {
        const hexRepr = try std.fmt.allocPrint(allocator, "U+{X:0>5}", .{self.code});

        return hexRepr;
    }

    pub fn binaryRepresentation(self: Utf8Codepoint, allocator: std.mem.Allocator) ![]const u8 {
        var binaryRepr = try allocator.alloc(u8, self.bytes.len * 8 + self.bytes.len - 1);

        for (self.bytes, 0..) |byte, idx| {
            _ = try std.fmt.bufPrint(binaryRepr[idx * 9 .. idx * 9 + 8], "{b:0>8}", .{byte});
            if (idx != self.bytes.len - 1) {
                binaryRepr[idx * 9 + 8] = ' ';
            }
        }

        return binaryRepr;
    }
};

test "utf-8 decode test" {
    // Test 1-byte UTF-8 (ASCII characters) - uses direct u21 cast
    try std.testing.expectEqual(@as(u21, 65), try decodeUtf8("A")); // 'A'
    try std.testing.expectEqual(@as(u21, 122), try decodeUtf8("z")); // 'z'
    try std.testing.expectEqual(@as(u21, 48), try decodeUtf8("0")); // '0'

    // Test 2-byte UTF-8 - uses decodeUtf8Len2
    try std.testing.expectEqual(@as(u21, 233), try decodeUtf8("é")); // 'é' (U+00E9)
    try std.testing.expectEqual(@as(u21, 1040), try decodeUtf8("А")); // Cyrillic 'А' (U+0410)
    try std.testing.expectEqual(@as(u21, 223), try decodeUtf8("ß")); // German 'ß' (U+00DF)
    try std.testing.expectEqual(@as(u21, 945), try decodeUtf8("α")); // Greek 'α' (U+03B1)

    // Test 3-byte UTF-8 - uses decodeUtf8Len3
    try std.testing.expectEqual(@as(u21, 8364), try decodeUtf8("€")); // Euro sign (U+20AC)
    try std.testing.expectEqual(@as(u21, 20013), try decodeUtf8("中")); // Chinese '中' (U+4E2D)
    try std.testing.expectEqual(@as(u21, 44032), try decodeUtf8("가")); // Korean '가' (U+AC00)
    try std.testing.expectEqual(@as(u21, 12354), try decodeUtf8("あ")); // Hiragana 'あ' (U+3042)

    // Test 4-byte UTF-8 - uses decodeUtf8Len4
    try std.testing.expectEqual(@as(u21, 128512), try decodeUtf8("😀")); // Grinning face (U+1F600)
    try std.testing.expectEqual(@as(u21, 128525), try decodeUtf8("😍")); // Heart eyes (U+1F60D)
    try std.testing.expectEqual(@as(u21, 127757), try decodeUtf8("🌍")); // Earth globe (U+1F30D)
    try std.testing.expectEqual(@as(u21, 128293), try decodeUtf8("🔥")); // Fire (U+1F525)
    try std.testing.expectEqual(@as(u21, 65536), try decodeUtf8("𐀀")); // Linear B (U+10000) - minimum 4-byte
}
