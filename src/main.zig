const std = @import("std");

const beefer = @import("./root.zig");
const args = beefer.args;
const parser = beefer.parser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    const app = args.Command{
        .name = "zs",
        .desc = "Ziss Password Manager",
        .flags = &.{.{
            .name = "something",
            .abbrev = "s",
            .desc = "fucker",
            .param = .{
                .name = "whatEven",
                .desc = "idk",
                .required = true,
                .type = .string,
            },
            .isEnableFlag = false,
        }},
        .subcommands = &.{.{
            .name = "subcommandOrSomething",
            .desc = "well im not sure",
            .param = .{
                .name = "subcommandParam",
                .desc = "asdsad",
                .required = true,
                .type = .int,
            },
            .flags = &.{.{
                .name = "theFlag",
                .desc = "asdads",
                .param = .{
                    .name = "prrr",
                    .desc = "asdsadsdsfwe",
                    .required = true,
                    .type = .int,
                },
            }},
        }},
        .param = .{
            .name = "stupidBitch",
            .desc = "the stupidest",
            .required = true,
            .type = .string,
        },
    };
    std.debug.print("app: {}\n", .{app.flags.?[0].param.?});

    const appData = try parser.collectArgs(app, allocator);

    std.debug.print("argData: {}\n", .{appData.flags.?.items[0].param.?.data.?});
    try app.subcommands.?[0].printHelp();
}
