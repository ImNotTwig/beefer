const std = @import("std");

pub const Command = struct {
    name: []const u8,
    desc: ?[]const u8,

    // can user defined flags make an appearance (runtime interpreted values)
    variadic_flags: bool = false,
    variadic_flag_type: ?ParamType = null,

    flags: ?[]const Flag = null,
    subcommands: ?[]const Command = null,
    param: ?Param = null,

    pub fn getIfFlag(comptime self: @This(), flag: []const u8) ?Flag {
        if (self.flags) |flags| inline for (flags) |f| {
            if (std.mem.eql(u8, "--" ++ f.name, flag)) return f;
            if (f.abbrev) |abbrev| if (std.mem.eql(u8, "-" ++ abbrev, flag)) return f;
        };
        return null;
    }
    pub fn ifFlag(comptime self: @This(), flag: []const u8) bool {
        if (self.flags) |flags| inline for (flags) |f| {
            if (std.mem.eql(u8, "--" ++ f.name, flag)) return true;
            if (f.abbrev) |abbrev| if (std.mem.eql(u8, "-" ++ abbrev, flag)) return true;
        };
        return false;
    }

    pub fn ifSubcommand(comptime self: @This(), subcommand: []const u8) bool {
        if (self.subcommands) |scs| inline for (scs) |sc| {
            if (std.mem.eql(u8, sc.name, subcommand)) return true;
        };
        return false;
    }

    pub fn printHelp(comptime self: @This()) !void {
        const stdout = std.io.getStdOut().writer();
        // description of the command
        try stdout.print("{s}\n\n", .{if (self.desc) |d| d else ""});
        // name of the command
        try stdout.print("Usage: {s}", .{self.name});
        // if we have flags, then tell the user that options go here
        if (self.flags) |l| if (l.len != 0) try stdout.print(" [OPTIONS]", .{});
        // if there are variadic flags, tell the user with ...
        if (self.variadic_flags) try stdout.print(" ...", .{});
        // if there are subcommands tell the user that they should go here
        if (self.subcommands) |l| if (l.len != 0) try stdout.print(" [COMMAND]", .{});
        // if this command has a parameter, tell the user what its type should be
        if (self.param) |param| switch (param.type) {
            .int => try stdout.print(" [{s}: int]", .{param.name}),
            .uint => try stdout.print(" [{s}: uint]", .{param.name}),
            .string => try stdout.print(" [{s}: str]", .{param.name}),
            .bool => try stdout.print(" [{s}: bool]", .{param.name}),
        };

        try stdout.print("\n", .{});

        if (self.variadic_flags) {
            try stdout.print(
                "Any amount of arbitrary flags with values of type: «{s}» may be put in place of «...»\n",
                .{@tagName(self.variadic_flag_type.?)},
            );
        }

        // max_width is for alignment, so that all subcommands or flags are printed
        // in a proper column
        var max_width: usize = 2;

        // getting the maximum length of the subcommand names
        if (self.subcommands) |c| {
            try stdout.print("\nCommands:\n", .{});
            inline for (c) |v| {
                if (v.name.len > max_width) max_width = v.name.len + 2;
                var len: usize = 0;
                if (v.param) |param| switch (param.type) {
                    .int => len += param.name.len + 3,
                    .uint => len += param.name.len + 4,
                    .string => len += param.name.len + 3,
                    .bool => len += param.name.len + 4,
                };
            }
        }

        if (self.subcommands) |c| {
            inline for (c) |v| {
                try stdout.print("  {s}", .{v.name});
                for (0..max_width - v.name.len) |_| try stdout.print(" ", .{});
                if (v.param) |param| switch (param.type) {
                    .int => try stdout.print("[{s}: int] ", .{param.name}),
                    .uint => try stdout.print("[{s}: uint] ", .{param.name}),
                    .string => try stdout.print("[{s}: str] ", .{param.name}),
                    .bool => try stdout.print("[{s}: bool] ", .{param.name}),
                };
                try stdout.print("\n", .{});
                if (v.desc) |d| try stdout.print("    {s}\n", .{d});
            }
        }

        max_width = 2;
        // getting the maximum length of the flag names
        if (self.flags) |c| {
            try stdout.print("\nOptions:\n", .{});
            inline for (c) |v| {
                const len = v.name.len + (if (v.abbrev) |a| a.len else 0);
                if (len > max_width) max_width = len + 2;
            }
        }

        if (self.flags) |c| {
            inline for (c) |v| {
                const len = v.name.len + (if (v.abbrev) |a| a.len else 0) - (if (v.abbrev == null) 3 else 0);
                if (v.abbrev) |a| {
                    try stdout.print("  -{s}, ", .{a});
                } else {
                    try stdout.print("  ", .{});
                }
                try stdout.print("--{s}", .{v.name});
                for (0..max_width - len) |_| try stdout.print(" ", .{});
                if (v.param) |param| switch (param.type) {
                    .int => try stdout.print("[{s}: int] ", .{param.name}),
                    .uint => try stdout.print("[{s}: uint] ", .{param.name}),
                    .string => try stdout.print("[{s}: str] ", .{param.name}),
                    .bool => try stdout.print("[{s}: bool] ", .{param.name}),
                };

                try stdout.print("\n", .{});
                if (v.desc) |d| try stdout.print("    {s}\n", .{d});
            }
        }
    }
};

pub const ParamType = enum { bool, int, uint, string };
pub const Param = struct {
    name: []const u8,
    desc: ?[]const u8 = null,
    required: bool = true,
    isVariadic: bool = false,
    type: ParamType,
};

pub const Flag = struct {
    name: []const u8,
    abbrev: ?[]const u8 = null,
    desc: ?[]const u8 = null,
    param: ?Param = null,
    // is this flag a toggle, if so, it cannot accept arguments
    // and is simply used as a setting toggle
    isEnableFlag: bool = false,
};
