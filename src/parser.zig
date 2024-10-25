const std = @import("std");
const args = @import("./args.zig");

// end goal: take the commands defined by the user, and make a struct based on that
// and parse arguments into that struct

fn getTotalArgsLength(comptime rootCommand: args.Command) usize {
    const paramsLength = if (rootCommand.params) |p| p.len else 0;
    var subcommandsLength: usize = 0;
    if (rootCommand.subcommands) |p| {
        for (p) |v| {
            subcommandsLength += getTotalArgsLength(v);
        }
    }
    var flagsLength: usize = 0;
    if (rootCommand.flags) |p| {
        flagsLength += p.len;
        for (p) |v| {
            flagsLength += if (v.params) |q| q.len else 0;
        }
    }
    return paramsLength + subcommandsLength + flagsLength;
}

// when we parse the first options, we should basically enter a seperate scope,
// so we know what to parse for next. leaving that scope when we know we're done parsing
// for that scopes params.

// We know that flags always come first, then subcommands, then parameters

// iterate through the list of strings that is argv
// if flag, collect parameters, if subcommand, we recursively parse the rest,
// of argv in that context, and we exit once we collect all the parameters

// if the parameter is optional for a parameter, then we need to check
// if the next argv is a subcommand or flag by comparing with known names
// or if it starts with «-» or «--» because of the case of arbitrary flags

// rootCommand
// |- Flag
// |  |- parameter
// |- Flag 2
// |  |- (optional) parameter
// |- Subcommand
// |  |- parameter
// |- Subcommand
// |  |- parameter
// |- parameter

const Arg = enum { command, flag, param };
const DataType = union(args.ParamType) {
    bool: bool,
    int: i32,
    uint: u32,
    string: []const u8,
};

const ArgWithData = struct {
    name: []const u8,
    data: ?DataType = null,

    subcommands: ?std.ArrayList(ArgWithData) = null,
    flags: ?std.ArrayList(ArgWithData) = null,
    param: ?*const ArgWithData = null,

    fn init(self: *@This(), allocator: std.mem.Allocator) void {
        self.flags = std.ArrayList(ArgWithData).init(allocator);

        self.subcommands = std.ArrayList(ArgWithData).init(allocator);
    }
};

//TODO: check if next argument after flag is actually a parameter,
// and not a subcommand or another flag
fn parseArgs(
    comptime rootCommand: args.Command,
    argv: [][*:0]u8,
    argData: ?*ArgWithData,
    allocator: std.mem.Allocator,
) usize {
    var i: usize = 0;

    while (true) {
        if (i >= argv.len) break;

        if (rootCommand.flags) |flags| for (flags) |flag| {
            if (rootCommand.ifFlag(std.mem.span(argv[i]))) {
                i += 1;
                if (flag.isEnableFlag) {
                    argData.?.flags.?.append(.{
                        .name = flag.name,
                        .data = .{ .bool = true },
                    }) catch @panic("get more ram");
                } else {
                    if (flag.param) |param| {
                        argData.?.flags.?.append(.{
                            .name = flag.name,
                        }) catch @panic("get more ram");
                        var f = &argData.?.flags.?.items[argData.?.flags.?.items.len - 1];
                        f.init(allocator);

                        if (i >= argv.len or rootCommand.ifFlag(std.mem.span(argv[i]))) {
                            if (param.required) {
                                std.log.err("«{s}»: missing «{s}» as a parameter", .{ flag.name, param.name });
                                std.process.exit(1);
                            } else {
                                continue;
                            }
                        }
                        i += 1;
                        f.param = &.{
                            .name = param.name,
                            .data = switch (param.type) {
                                .int => DataType{ .int = std.fmt.parseInt(i32, std.mem.span(argv[i]), 0) catch {
                                    std.log.err("«{s}» is not of type: «int»", .{param.name});
                                    std.process.exit(1);
                                } },

                                .uint => DataType{ .uint = std.fmt.parseInt(u32, std.mem.span(argv[i]), 0) catch {
                                    std.log.err("«{s}» is not of type: «uint»", .{param.name});
                                    std.process.exit(1);
                                } },

                                .string => DataType{ .string = std.mem.span(argv[i]) },

                                .bool => if (std.mem.eql(u8, std.mem.span(argv[i]), "true"))
                                    DataType{ .bool = true }
                                else if (std.mem.eql(u8, std.mem.span(argv[i]), "false"))
                                    DataType{ .bool = false }
                                else {
                                    std.log.err("«{s}» is not of type: «bool»", .{param.name});
                                    std.process.exit(1);
                                },
                            },
                        };

                        i += 1;
                    }
                }
            }
        };
        if (rootCommand.subcommands) |scs| inline for (scs) |sc| {
            if (std.mem.eql(u8, sc.name, std.mem.span(argv[i]))) {
                // i += 1;
                i += parseArgs(sc, argv[i..], argData, allocator);
            }
        };
        if (rootCommand.param) |param| {
            argData.?.param = &.{
                .name = rootCommand.name,
            };

            if (i >= argv.len or rootCommand.ifFlag(std.mem.span(argv[i]))) {
                if (param.required) {
                    std.log.err("«{s}»: missing «{s}» as a parameter", .{ rootCommand.name, param.name });
                    std.process.exit(1);
                } else {
                    continue;
                }
            }
            i += 1;
            argData.?.param = &.{
                .name = param.name,
                .data = switch (param.type) {
                    .int => DataType{ .int = std.fmt.parseInt(i32, std.mem.span(argv[i]), 0) catch {
                        std.log.err("«{s}» is not of type: «int»", .{param.name});
                        std.process.exit(1);
                    } },

                    .uint => DataType{ .uint = std.fmt.parseInt(u32, std.mem.span(argv[i]), 0) catch {
                        std.log.err("«{s}» is not of type: «uint»", .{param.name});
                        std.process.exit(1);
                    } },

                    .string => DataType{ .string = std.mem.span(argv[i]) },

                    .bool => if (std.mem.eql(u8, std.mem.span(argv[i]), "true"))
                        DataType{ .bool = true }
                    else if (std.mem.eql(u8, std.mem.span(argv[i]), "false"))
                        DataType{ .bool = false }
                    else {
                        std.log.err("«{s}» is not of type: «bool»", .{param.name});
                        std.process.exit(1);
                    },
                },
            };

            i += 1;
        }
    }
    return i;
}

pub fn collectArgs(comptime rootCommand: args.Command, allocator: std.mem.Allocator) !ArgWithData {
    try rootCommand.printHelp();
    // const len = comptime getTotalArgsLength(rootCommand);
    // try std.testing.expect(rootCommand.doesFlagExist("--fuck") == true);
    // try std.testing.expect(rootCommand.doesFlagExist("--asd") == false);
    // try std.testing.expect(rootCommand.doesFlagExist("-a") == true);

    const argv = std.os.argv;
    var appData: ArgWithData = .{
        .name = rootCommand.name,
    };
    appData.init(allocator);
    _ = parseArgs(rootCommand, argv[1..], &appData, allocator);
    return appData;
}
