const std = @import("std");
const tv = @import("./table_view.zig");
const utf8_decode = @import("utf8_decode.zig");

const max_byte = 1 << 10 << 10 << 10; // 1GB

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // init table
    var table_view = try tv.TableView.init(allocator, &.{ "character", "unicode(decimal)", "unicode(hex)", "utf-8(binary)" });
    defer table_view.deinit();

    // read from stdin
    const input_str = try std.io.getStdIn().readToEndAlloc(allocator, max_byte);
    defer allocator.free(input_str);

    var view = utf8_decode.Utf8View.init(input_str[0 .. input_str.len - 1]); // exclude string sentiel

    // append rows to table
    while (view.next()) |codePoint| {
        const decimalRepr = try std.fmt.allocPrint(allocator, "{d}", .{codePoint.code});
        defer allocator.free(decimalRepr);
        const hexRepr = try codePoint.hexRepresentation(allocator);
        defer allocator.free(hexRepr);
        const binaryRepr = try codePoint.binaryRepresentation(allocator);
        defer allocator.free(binaryRepr);

        try table_view.appendRow(&.{ codePoint.bytes, decimalRepr, hexRepr, binaryRepr });
    }

    // print table to stdout
    try table_view.printStd();
}
