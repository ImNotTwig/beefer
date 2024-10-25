const std = @import("std");

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
    arbitraryFlagType: ?ParamType = null,
    arbitraryFlagLimit: usize = 0,

    flags: ?[]const Flag = null,
    subcommands: ?[]const Command = null,
    params: ?[]const Param = null,

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

    pub fn printHelp(comptime self: @This()) !void {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("{s}\n\n", .{if (self.desc) |d| d else ""});
        try stdout.print("Usage: {s}", .{self.name});
        if (self.flags) |l| if (l.len != 0) try stdout.print(" [OPTIONS]", .{});
        if (self.arbitraryFlags) try stdout.print(" ...", .{});
        if (self.subcommands) |l| if (l.len != 0) try stdout.print(" [COMMAND]", .{});
        if (self.params) |l| if (l.len != 0) inline for (l) |v| {
            switch (v.type) {
                .int => try stdout.print(" [{s}: int]", .{v.name}),
                .uint => try stdout.print(" [{s}: uint]", .{v.name}),
                .string => try stdout.print(" [{s}: str]", .{v.name}),
                .bool => try stdout.print(" [{s}: bool]", .{v.name}),
            }
        };

        try stdout.print("\n", .{});

        if (self.arbitraryFlags) {
            try stdout.print("Any amount of arbitrary flags with values of type: «{s}» may be put in place of «...»\n", .{@tagName(self.arbitraryFlagType)});
        }

        var maxWidth: usize = 2;
        if (self.subcommands) |c| {
            try stdout.print("\nCommands:\n", .{});
            inline for (c) |v| {
                if (v.name.len > maxWidth) maxWidth = v.name.len + 2;
                var len: usize = 0;
                if (v.params) |p| inline for (p) |a| {
                    switch (a.type) {
                        .int => len += a.name.len + 3,
                        .uint => len += a.name.len + 4,
                        .string => len += a.name.len + 3,
                        .bool => len += a.name.len + 4,
                    }
                };
            }
        }
        if (self.subcommands) |c| {
            inline for (c) |v| {
                try stdout.print("  {s}", .{v.name});
                for (0..maxWidth - v.name.len) |_| try stdout.print(" ", .{});
                if (v.params) |p| inline for (p) |a| {
                    switch (a.type) {
                        .int => try stdout.print("[{s}: int] ", .{a.name}),
                        .uint => try stdout.print("[{s}: uint] ", .{a.name}),
                        .string => try stdout.print("[{s}: str] ", .{a.name}),
                        .bool => try stdout.print("[{s}: bool] ", .{a.name}),
                    }
                };
                try stdout.print("\n", .{});
                if (v.desc) |d| try stdout.print("    {s}\n", .{d});
            }
        }

        maxWidth = 2;
        if (self.flags) |c| {
            try stdout.print("\nOptions:\n", .{});
            inline for (c) |v| {
                const len = v.name.len + (if (v.abbrev) |a| a.len else 0);
                if (len > maxWidth) maxWidth = len + 2;
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
                for (0..maxWidth - len) |_| try stdout.print(" ", .{});
                if (v.params) |p| inline for (p) |a| {
                    switch (a.type) {
                        .int => try stdout.print("[{s}: int] ", .{a.name}),
                        .uint => try stdout.print("[{s}: uint] ", .{a.name}),
                        .string => try stdout.print("[{s}: str] ", .{a.name}),
                        .bool => try stdout.print("[{s}: bool] ", .{a.name}),
                    }
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
    type: ParamType,
};

pub const Flag = struct {
    name: []const u8,
    abbrev: ?[]const u8,
    desc: ?[]const u8,
    params: ?[]const Param,
    // is this flag a toggle, if so, it cannot accept arguments
    // and is simply used as a setting toggle
    isEnableFlag: bool = false,
};
