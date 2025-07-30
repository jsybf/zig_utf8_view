const std = @import("std");

pub const TableView = struct {
    allocator: std.mem.Allocator,
    headers: []const []const u8,
    rows: std.ArrayList([]const []const u8),

    pub const TableViewError = error{ ColumnSizeMismatch, // column size of every row(including header) should be equal
    OutOfMemory // inherit from std.mem.Allocator.Error
    };

    pub fn init(allocator: std.mem.Allocator, headers: []const []const u8) !TableView {
        return TableView{ .allocator = allocator, .headers = headers, .rows = std.ArrayList([]const []const u8).init(allocator) };
    }
    pub fn deinit(self: *TableView) void {
        for (self.rows.items) |row| {
            for (row) |cell| {
                self.allocator.free(cell);
            }
            self.allocator.free(row);
        }
        self.rows.deinit();
    }

    pub fn appendRow(self: *TableView, row: []const []const u8) TableViewError!void {
        if (self.headers.len != row.len) {
            return TableViewError.ColumnSizeMismatch;
        }

        const copied = try self.allocator.alloc([]const u8, row.len);
        for (row, 0..) |cell, idx| {
            copied[idx] = try self.allocator.dupe(u8, cell);
        }

        try self.rows.append(copied);
    }
    fn getMaxWidthsPerColumn(self: TableView) ![]usize {
        var col_max_widths = try self.allocator.alloc(usize, self.headers.len);

        for (self.headers, 0..) |header, idx| {
            col_max_widths[idx] = try std.unicode.utf8CountCodepoints(header);
        }

        for (self.rows.items) |row| {
            for (row, 0..) |cell, idx| {
                const width = try std.unicode.utf8CountCodepoints(cell);
                col_max_widths[idx] = @max(col_max_widths[idx], width);
            }
        }

        return col_max_widths;
    }

    fn printStdLine(self: TableView, col_max_widths: []usize, left_char: []const u8, delimiter: []const u8, right_char: []const u8, cells: []const []const u8) void {
        std.debug.assert(self.headers.len == col_max_widths.len);
        std.debug.assert(self.headers.len == cells.len);

        std.debug.print("{s}", .{left_char});

        for (col_max_widths, 0..) |width, idx| {
            std.debug.print("{[value]s: <[width]}", .{ .value = cells[idx], .width = width });

            if (idx != col_max_widths.len - 1) {
                std.debug.print("{s}", .{delimiter});
            }
        }

        std.debug.print("{s}\n", .{right_char});
    }

    pub fn printStd(self: TableView) !void {
        const col_max_widths = try self.getMaxWidthsPerColumn();
        defer self.allocator.free(col_max_widths);

        // create strings like ────── used for horizontal line.
        const hor_line_cells = try self.allocator.alloc([]u8, self.headers.len);
        defer {
            for (hor_line_cells) |cell| {
                self.allocator.free(cell);
            }
            self.allocator.free(hor_line_cells);
        }
        for (col_max_widths, 0..) |width, idx| {
            hor_line_cells[idx] = try repeatString(self.allocator, "─", width);
        }

        // print 1st line
        self.printStdLine(col_max_widths, "┌", "┬", "┐", hor_line_cells);
        // print 2nd line
        self.printStdLine(col_max_widths, "│", "│", "│", self.headers);
        // print 3rd line
        self.printStdLine(col_max_widths, "├", "┼", "┤", hor_line_cells);
        // print rows
        for (self.rows.items, 0..) |row, idx| {
            self.printStdLine(col_max_widths, "│", "│", "│", row);
            if (idx != self.rows.items.len - 1) {
                self.printStdLine(col_max_widths, "├", "┼", "┤", hor_line_cells);
            }
        }
        // print last line
        self.printStdLine(col_max_widths, "└", "┴", "┘", hor_line_cells);
    }
};

fn repeatString(allocator: std.mem.Allocator, str: []const u8, repeats: usize) ![]u8 {
    const result = try allocator.alloc(u8, str.len * repeats);

    for (0..repeats) |i| {
        @memcpy(result[i * str.len .. (i + 1) * str.len], str);
    }

    return result;
}
