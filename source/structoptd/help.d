module structoptd.help;

@safe:

import std.range : isOutputRange;
import std.algorithm : filter, joiner;
import std.array : array;
import std.format : format;

import structoptd.attribute;
import structoptd.argument;

/// putHelpMessage puts the help message of the command to the OutputRange.
public void putHelpMessage(Cmd, T)(T w)
        if (isCommand!Cmd && isOutputRange!(T, char))
{
    enum cmd = getCommand!Cmd;
    w ~= cmd.name;
    if (cmd.about != "")
    {
        w ~= format!" %s"(cmd.about);
    }
    w ~= '\n';
    w ~= "USAGE:\n";
    w ~= format!"%s [OPTIONS]\n\n"(cmd.name);
    alias arguments = getArguments!Cmd;
    putFlags(w, arguments);
    putOptions(w, arguments);
    putPositionalArguments(w, arguments);
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
example [OPTIONS]

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

private void putOptions(T)(T w, const Argument[] arguments)
        if (isOutputRange!(T, char))
{
    const options = arguments.filter!((a) => a.isOption).array;
    if (options.length == 0)
        return;
    w ~= "\nOPTIONS:\n";
    foreach (option; options)
    {
        w ~= "    ";
        if (!option.short_.isNull)
        {
            w ~= option.short_.get;
            if (!option.long_.isNull)
            {
                w ~= ", ";
            }
        }
        if (!option.long_.isNull)
        {
            w ~= option.long_.get;
        }
        w ~= " <";
        w ~= option.fieldName;
        w ~= ">\n";
    }
}

private void putFlags(T)(T w, const Argument[] arguments)
        if (isOutputRange!(T, char))
{
    const flags = arguments.filter!((a) => a.isFlag).array;
    w ~= "FLAGS:
    -h, --help      Prints help information
    -V, --version   Prints version information
";
    foreach (flag; flags)
    {
        w ~= "    ";
        if (!flag.short_.isNull)
        {
            w ~= flag.short_.get;
            if (!flag.long_.isNull)
            {
                w ~= ", ";
            }
        }
        if (!flag.long_.isNull)
        {
            w ~= flag.long_.get;
        }
        w ~= "\n";
    }
}

private void putPositionalArguments(T)(T w, const Argument[] arguments)
        if (isOutputRange!(T, char))
{
    const posArgs = arguments.filter!((a) => a.isPositional).array;
    if (posArgs.length == 0) return;
    w ~= "\nArgs:\n";
    foreach (posArg; posArgs)
    {
        w ~= "    <";
        w ~= posArg.fieldName;
        w ~= ">\n";
    }
}
