const std = @import("std");

// So we want to declare subcommands and options, but we also want to allow for
// arbitrary positional arguments

pub fn main() !void {
    var argList = std.process.args();
    std.debug.print("{s}\n", .{argList.next().?});
}
