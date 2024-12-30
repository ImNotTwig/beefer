const std = @import("std");

const beefer = @import("./root.zig");
const args = beefer.args;
const parser = beefer.parser;

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // const app = comptime args.Command{
    //     .name = "zs",
    //     .desc = "Ziss Password Manager",
    //     .flags = &.{.{
    //         .name = "something",
    //         .abbrev = "s",
    //         .desc = "fucker",
    //         .param = .{
    //             .name = "whatEven",
    //             .desc = "idk",
    //             .required = true,
    //             .type = .uint,
    //         },
    //         .isEnableFlag = false,
    //     }},
    //     .subcommands = &.{.{
    //         .name = "add",
    //         .desc = "add an account to the store (use variadic flags to specify fields)",
    //         .param = .{
    //             .name = "path",
    //             .desc = "the virtual path for the account in the store",
    //             .required = true,
    //             .type = .string,
    //         },
    //         .variadic_flags = true,
    //         .variadic_flag_type = .string,
    //     }},
    // };

    // const appData = try parser.collectArgs(app, allocator);
    // _ = appData;
}
