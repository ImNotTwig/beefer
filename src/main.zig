const std = @import("std");

const beefer = @import("./root.zig");
const args = beefer.args;
const parser = beefer.parser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const app = args.Command{
        .name = "zs",
        .desc = "Ziss Password Manager",
        .flags = &.{
            .{
                .name = "something",
                .abbrev = "s",
                .desc = "fucker",
                .params = &.{ .{
                    .name = "whatEven",
                    .desc = "idk",
                    .required = true,
                    .type = .string,
                }, .{
                    .name = "wellMaybe",
                    .desc = "fuck",
                    .required = true,
                    .type = .int,
                }, .{
                    .name = "fucker",
                    .desc = "hm",
                    .required = false,
                    .type = .uint,
                } },
                .isEnableFlag = false,
            },
        },
        .subcommands = null,
        .params = null,
    };
    std.debug.print("app: {}\n", .{app.flags.?[0].params.?[0]});

    const appData = try parser.collectArgs(app, allocator);

    std.debug.print("argData: {}\n", .{appData.flags.?.items[0].params.?.items[0].data.?});
}
