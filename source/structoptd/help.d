module structoptd.help;

@safe:

import std.range : isOutputRange, empty;
import std.algorithm : filter, joiner, all, map;
import std.array : array;
import std.format : format;

import structoptd.attribute;
import structoptd.argument;

/// putVersion puts the version information of the command.
public void putVersion(Cmd, T)(T w) if (isCommand!Cmd && isOutputRange!(T, char))
{
    enum cmd = getCommand!Cmd;
    w.put(cmd.name);
    w.put(" ");
    w.put(cmd.version_);
    w.put("\n");
}

/// putHelpMessage puts the help message of the command to the OutputRange.
public void putHelpMessage(Cmd, T)(T w)
        if (isCommand!Cmd && isOutputRange!(T, char))
{
    enum cmd = getCommand!Cmd;
    w.put(cmd.name);
    if (cmd.about != "")
    {
        w.put(format!" %s"(cmd.about));
    }
    w.put('\n');
    alias arguments = getArguments!Cmd;
    putUsage(w, cmd, arguments);
    putFlags(w, arguments.flags);
    putOptions(w, arguments.options);
    putPositionalArguments(w, arguments.positionalArguments);
}

unittest
{
    @command("example", "An example of structopt usage") struct Opt
    {
        @argument!(short_, long_) string name;
        @argument!(short_('o'), long_) string output;
        @argument!(short_('d')) string diff;
        @argument!(long_) string input;
        @argument!(short_, long_) bool verbose;
        @argument!() string arg1;
        @argument!() string arg2;
    }

    static assert(!is(typeof(parseArgs!int([]))));

    import std.array : appender;

    auto w = appender("");
    putHelpMessage!Opt(w);

    immutable expected = `example
USAGE:
    example [FLAGS] [OPTIONS] <arg1> <arg2>

FLAGS:
    -h, --help      Prints help information
    -V, --version   Prints version information
    -v, --verbose

OPTIONS:
    -n, --name <name>
    -o, --output <output>
    -d <diff>
    --input <input>

Args:
    <arg1>
    <arg2>
`;
    assert(w.data == expected, w.data);
}

/// putUsage puts the usage of the command to the OutputRange.
public void putUsage(Cmd, T)(T w) if (isOutputRange!(T, char) && isCommand!Cmd)
{
    putUsage(w, getCommand!Cmd, getArguments!Cmd);
}

/// ditto
public void putUsage(T)(T w, const command cmd, const Arguments arguments)
        if (isOutputRange!(T, char))
{
    w.put("USAGE:\n    ");
    w.put(cmd.name);
    if (!arguments.flags.empty)
    {
        w.put(" [FLAGS]");
    }
    if (!arguments.options.empty)
    {
        w.put(" [OPTIONS]"); // TODO: required options.
    }
    if (!arguments.positionalArguments.empty)
    {
        w.put(" ");
        w.put(arguments.positionalArguments.map!((a) => format!"<%s>"(a.fieldName)).joiner(" "));
    }
    w.put("\n");
}

private void putOptions(T)(T w, const Argument[] arguments)
        if (isOutputRange!(T, char))
in
{
    assert(arguments.all!"a.isOption");
}
do
{
    const options = arguments.filter!((a) => a.isOption).array;
    if (options.length == 0)
        return;
    w.put("\nOPTIONS:\n");
    foreach (option; options)
    {
        w.put("    ");
        if (!option.short_.isNull)
        {
            w.put(option.short_.get);
            if (!option.long_.isNull)
            {
                w.put(", ");
            }
        }
        if (!option.long_.isNull)
        {
            w.put(option.long_.get);
        }
        w.put(" <");
        w.put(option.fieldName);
        w.put(">\n");
    }
}

private void putFlags(T)(T w, const Argument[] arguments)
        if (isOutputRange!(T, char))
in
{
    assert(arguments.all!"a.isFlag");
}
do
{
    const flags = arguments.filter!((a) => a.isFlag).array;
    w.put("\nFLAGS:
    -h, --help      Prints help information
    -V, --version   Prints version information
");
    foreach (flag; flags)
    {
        w.put("    ");
        if (!flag.short_.isNull)
        {
            w.put(flag.short_.get);
            if (!flag.long_.isNull)
            {
                w.put(", ");
            }
        }
        if (!flag.long_.isNull)
        {
            w.put(flag.long_.get);
        }
        w.put("\n");
    }
}

private void putPositionalArguments(T)(T w, const Argument[] arguments)
        if (isOutputRange!(T, char))
in
{
    assert(arguments.all!"a.isPositional");
}
do
{
    const posArgs = arguments.filter!((a) => a.isPositional).array;
    if (posArgs.length == 0)
        return;
    w.put("\nArgs:\n");
    foreach (posArg; posArgs)
    {
        w.put("    <");
        w.put(posArg.fieldName);
        w.put(">\n");
    }
}
