const std = @import("std");

/// Useful for 0-based iterations, upper bound is non-inclusive
pub fn range(len: usize) []const void {
    return @as([*]void, undefined)[0..len];
}

test "range" {
    const expect = std.testing.expect;

    var count: u16 = 0;
    for (range(69)) |_, i| {
        try expect(count == i);
        count += 1;
    }
    try expect(count == 69);
}
