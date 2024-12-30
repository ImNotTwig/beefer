const std = @import("std");
const args = @import("./args.zig");

fn getTotalArgsLength(comptime root_command: args.Command) usize {
    const params_length = if (root_command.params) |p| p.len else 0;
    var subcommands_length: usize = 0;
    if (root_command.subcommands) |p| {
        for (p) |v| {
            subcommands_length += getTotalArgsLength(v);
        }
    }
    var flags_length: usize = 0;
    if (root_command.flags) |p| {
        flags_length += p.len;
        for (p) |v| {
            flags_length += if (v.params) |q| q.len else 0;
        }
    }
    return params_length + subcommands_length + flags_length;
}

const ArgDataType = union(args.ParamType) {
    bool: bool,
    int: i32,
    uint: u32,
    string: []const u8,
};

const ArgWithData = struct {
    name: []const u8,
    data: ?ArgDataType = null,

    subcommands: ?std.ArrayList(ArgWithData) = null,
    flags: ?std.ArrayList(ArgWithData) = null,
    param: ?*const ArgWithData = null,

    fn init(self: *@This(), allocator: std.mem.Allocator) void {
        self.flags = std.ArrayList(ArgWithData).init(allocator);

        self.subcommands = std.ArrayList(ArgWithData).init(allocator);
    }

    fn deinit(self: *@This()) void {
        if (self.subcommands) |*scs| for (scs.*) |*sc| {
            sc.deinit();
        };
        if (self.subcommands) |*scs| scs.deinit();
        if (self.flags) |*flags| for (flags.*) |*flag| {
            flag.deinit();
        };
        if (self.flags) |*flags| flags.deinit();
    }
};

fn parseArgToData(param: args.Param, argument_string: []u8) ArgDataType {
    return switch (param.type) {
        .int => ArgDataType{ .int = std.fmt.parseInt(i32, argument_string, 0) catch {
            std.log.err("«{s}» is not of type: «int»", .{param.name});
            std.process.exit(1);
        } },

        .uint => ArgDataType{ .uint = std.fmt.parseInt(u32, argument_string, 0) catch {
            std.log.err("«{s}» is not of type: «uint»", .{param.name});
            std.process.exit(1);
        } },

        .string => ArgDataType{ .string = argument_string },

        .bool => if (std.mem.eql(u8, argument_string, "true"))
            ArgDataType{ .bool = true }
        else if (std.mem.eql(u8, argument_string, "false"))
            ArgDataType{ .bool = false }
        else {
            std.log.err("«{s}» is not of type: «bool»", .{param.name});
            std.process.exit(1);
        },
    };
}

//TODO: this function should probably be split into multiple
//TODO: cover variadic arguments
fn parseArgs(
    comptime root_command: args.Command,
    argv: [][]u8,
    arg_data: ?*ArgWithData,
    allocator: std.mem.Allocator,
) usize {
    var argv_idx: usize = 0;

    while (true) {
        if (argv_idx >= argv.len) break;

        if (root_command.flags) |flags| for (flags) |flag| {
            if (root_command.ifFlag(argv[argv_idx])) {
                argv_idx += 1;
                // is this flag simply a toggle or not, e.g: --enable
                if (flag.isEnableFlag) {
                    arg_data.?.flags.?.append(.{
                        .name = flag.name,
                        .data = .{ .bool = true },
                    }) catch @panic("get more ram");
                    continue;
                }
                if (flag.param) |param| {
                    arg_data.?.flags.?.append(.{
                        .name = flag.name,
                    }) catch @panic("get more ram");

                    const flags_list = &arg_data.?.flags.?.items;
                    var f = flags_list.*[flags_list.len - 1];
                    f.init(allocator);

                    // make sure required parameters are filled out
                    if (argv_idx >= argv.len or root_command.ifFlag(argv[argv_idx])) {
                        if (param.required) {
                            std.log.err("«{s}»: missing «{s}» as a parameter", .{ flag.name, param.name });
                            std.process.exit(1);
                        }
                        if (argv_idx >= argv.len) break;
                        continue;
                    }

                    f.param = &.{
                        .name = param.name,
                        .data = parseArgToData(param, argv[argv_idx]),
                    };

                    argv_idx += 1;
                }
            }
        };
        if (root_command.subcommands) |scs| inline for (scs) |sc| {
            if (std.mem.eql(u8, sc.name, argv[argv_idx])) {
                argv_idx += parseArgs(sc, argv[argv_idx + 1 ..], arg_data, allocator) + 1;
                // further arguments should not be interpreted as a subcommand
                break;
            }
        };

        if (root_command.param) |param| {
            arg_data.?.param = &.{
                .name = root_command.name,
            };

            if (argv_idx >= argv.len or root_command.ifFlag(argv[argv_idx])) {
                if (param.required) {
                    std.log.err("«{s}»: missing «{s}» as a parameter", .{ root_command.name, param.name });
                    std.process.exit(1);
                } else {
                    continue;
                }
            }

            arg_data.?.param = &.{
                .name = param.name,
                .data = parseArgToData(param, argv[argv_idx]),
            };

            argv_idx += 1;
        }
        if (argv_idx + 1 >= argv.len) return argv_idx;
        if (!root_command.ifFlag(argv[argv_idx + 1]) and
            !root_command.ifSubcommand(argv[argv_idx + 1]) and
            root_command.param != null)
        {
            return argv_idx;
        }
    }
    return argv_idx;
}

pub fn getArgv(allocator: std.mem.Allocator) ![][]u8 {
    const argv = std.os.argv;
    var new_argv = std.ArrayList([]u8).init(allocator);
    defer new_argv.deinit();

    for (argv) |arg| {
        const new_arg = arg[0..std.mem.len(arg)];
        try new_argv.append(new_arg);
    }

    return allocator.dupe([]u8, new_argv.items[0..]);
}

pub fn collectArgs(comptime root_command: args.Command, allocator: std.mem.Allocator) !ArgWithData {
    try root_command.printHelp();
    const argv = try getArgv(allocator);

    var app_data: ArgWithData = .{
        .name = root_command.name,
    };
    app_data.init(allocator);
    const len = parseArgs(root_command, argv[1..], &app_data, allocator);
    if (len < argv.len - 1) {
        std.log.err("Unexpected arguments: «{s}»...", .{argv[len + 1]});
        std.process.exit(1);
    }
    return app_data;
}
