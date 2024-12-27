const std = @import("std");

const beefer = @import("./root.zig");
const args = beefer.args;
const parser = beefer.parser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const app = comptime args.Command{
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
                .type = .uint,
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

    const appData = try parser.collectArgs(app, allocator);
    _ = appData;
}
