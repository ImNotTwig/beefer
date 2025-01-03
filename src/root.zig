const std = @import("std");
pub const args = @import("./args.zig");
pub const parser = @import("./parser.zig");

test {
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
            .name = "add",
            .desc = "add an account to the store (use variadic flags to specify fields)",
            .param = .{
                .name = "path",
                .desc = "the virtual path for the account in the store",
                .required = true,
                .type = .string,
            },
            .variadic_flags = true,
            .variadic_flag_type = .string,
        }},
    };

    var argv = [_][]const u8{"ziss"};

    const appData = try parser.collectArgs(app, &argv, allocator);
    _ = appData;
}
