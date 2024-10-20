const std = @import("std");
const testing = std.testing;
const expect = testing.expect;

// we want to end up with a list of commands with their respective arguments
// if they have any, which means its optional
// [][]const u8
// parse out things in "", keywords, numbers, flags, etc
// check when keywords or flags are supposed to have a value immediately following it, and
// map those arguments to said keyword or flag.
// we will need to be able to stop parsing for arguments when we encounter a -- or keyword,
// because that wouldn't be a valid argument, because like if you wanted to pass an argument,
// that has the same name as a keyword, then you would put it in ""

// we will define valid keywords using the comptime values of subcommands, we can definitely
// do this because subcommands cannot be arbitrary

// there can only be one subcommand per scope, so if a value shares the name of a subcommand,
// after the first instance of the subcommand name showing up,
// there shouldnt be a problem, but we should probably like tell the user anyways

// we should only assume -1 is a negative number when the subcommand or flag preceeding it,
// is expecting an int/i32

pub const Command = struct {
    name: []const u8,
    desc: ?[]const u8,

    // can user defined flags make an appearance (runtime interpreted values)
    arbitraryFlags: bool = false,
    arbitraryFlagType: ?enum { string, int, uint } = null,

    flags: ?[]const Flag,
    subcommands: ?[]const Command,
    params: ?[]const FlagValue = null,

    pub fn printHelp(self: @This()) void {
        std.debug.print("{s}\n\n", .{if (self.desc) |d| d else ""});
        std.debug.print("Usage: {s}", .{self.name});
        if (self.flags) |l| if (l.len != 0) std.debug.print(" [OPTIONS]", .{});
        if (self.arbitraryFlags) std.debug.print(" ...", .{});
        if (self.subcommands) |l| if (l.len != 0) std.debug.print(" [COMMAND]", .{});
        if (self.params) |l| if (l.len != 0) for (l) |v| {
            switch (v) {
                .int => std.debug.print(" [<{s}>: int]", .{v.int.name}),
                .uint => std.debug.print(" [<{s}>: uint]", .{v.uint.name}),
                .string => std.debug.print(" [<{s}>: str]", .{v.string.name}),
            }
        };

        std.debug.print("\n", .{});

        if (self.arbitraryFlags) {
            std.debug.print("Any amount of arbitrary flags with values of type: '{s}` may be put in place of '...`\n", .{@tagName(self.arbitraryFlagType.?)});
        }

        var maxWidth: usize = 2;
        if (self.subcommands) |c| {
            std.debug.print("\nCommands:\n", .{});
            for (c) |v| {
                if (v.name.len > maxWidth) maxWidth = v.name.len + 2;
            }
        }
        if (self.subcommands) |c| {
            for (c) |v| {
                std.debug.print("  {s}", .{v.name});
                for (0..maxWidth - v.name.len) |_| std.debug.print(" ", .{});
                if (v.desc) |d| std.debug.print("{s}\n", .{d});
            }
        }
        maxWidth = 2;
        if (self.flags) |c| {
            std.debug.print("\nOptions:\n", .{});
            for (c) |v| {
                const len = v.name.len + (if (v.abbrev) |a| a.len else 0);
                if (len > maxWidth) maxWidth = len + 1;
            }
        }
        if (self.flags) |c| {
            var maxParamWidth: usize = 2;
            for (c) |v| {
                if (v.params) |p| for (p) |a| {
                    switch (a) {
                        .int => {
                            if (a.int.name.len > maxParamWidth + 3) maxParamWidth = a.int.name.len + 2 + 3;
                        },
                        .uint => {
                            if (a.uint.name.len > maxParamWidth + 4) maxParamWidth = a.uint.name.len + 2 + 4;
                        },
                        .string => {
                            if (a.string.name.len > maxParamWidth + 5) maxParamWidth = a.string.name.len + 2 + 3;
                        },
                    }
                };
            }
            for (c) |v| {
                const len = v.name.len + (if (v.abbrev) |a| a.len else 0);
                if (v.abbrev) |a| {
                    std.debug.print("  -{s}, ", .{a});
                } else {
                    std.debug.print("  ", .{});
                }
                std.debug.print("--{s}", .{v.name});
                for (0..maxWidth - len) |_| std.debug.print(" ", .{});
                if (v.params) |p| for (p) |a| {
                    switch (a) {
                        .int => |x| {
                            std.debug.print(" [<{s}>: int]", .{x.name});
                            for (0..maxParamWidth - x.name.len - 3) |_| std.debug.print(" ", .{});
                        },
                        .uint => |x| {
                            std.debug.print(" [<{s}>: uint]", .{x.name});
                            for (0..maxParamWidth - x.name.len - 4) |_| std.debug.print(" ", .{});
                        },
                        .string => |x| {
                            std.debug.print(" [<{s}>: str]", .{x.name});
                            for (0..maxParamWidth - x.name.len - 3) |_| std.debug.print(" ", .{});
                        },
                    }
                };
                if (v.desc) |d| std.debug.print("{s}", .{d});
                std.debug.print("\n", .{});
            }
        }
    }
};

pub const FlagValue = union(enum) {
    const meta = struct {
        name: []const u8,
        desc: ?[]const u8 = null,
    };
    int: meta,
    uint: meta,
    string: meta,
};

pub const Flag = struct {
    name: []const u8,
    abbrev: ?[]const u8,
    desc: ?[]const u8,
    params: ?[]const FlagValue,
};

test "FlagValues" {
    const addCommand = Command{
        .flags = null,
        .subcommands = null,
        .params = &.{
            .{ .string = .{
                .name = "path",
                .desc = "The virtual path of the account in the store.",
            } },
            .{ .int = .{
                .name = "num",
                .desc = "some number arg idk",
            } },
        },
        .desc = "add an account to the store",
        .name = "add",
    };
    const rmCommand = Command{
        .flags = null,
        .subcommands = null,
        .params = &.{
            .{ .string = .{
                .name = "path",
                .desc = "The virtual path of the account in the store.",
            } },
            .{ .int = .{
                .name = "num",
                .desc = "some number arg idk",
            } },
        },
        .desc = "remove an account from the store",
        .name = "remove",
    };

    const zsSubcommands = &[_]Command{
        addCommand,
        rmCommand,
    };
    const app = Command{
        .name = "zs",
        .desc = "ziss password manager",
        .subcommands = zsSubcommands,
        .params = &.{
            .{ .string = .{
                .name = "something",
                .desc = "something",
            } },
        },
        .arbitraryFlags = true,
        .arbitraryFlagType = .string,
        .flags = &.{
            .{
                .name = "fuck",
                .abbrev = "f",
                .desc = "fuck idk",
                .params = &.{
                    .{ .int = .{
                        .name = "shit",
                        .desc = "what the sigma",
                    } },
                },
            },
            .{
                .name = "ass",
                .abbrev = "a",
                .desc = "assfuckery",
                .params = &.{
                    .{ .uint = .{
                        .name = "awhdasjkhd",
                        .desc = "???",
                    } },
                },
            },
        },
    };

    app.printHelp();
}
