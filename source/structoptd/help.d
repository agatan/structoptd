module structoptd.help;

@safe:

import std.range : isOutputRange;
import std.algorithm : filter, joiner;
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
    w ~= "FLAGS:
    -h, --help      Prints help information
    -V, --version   Prints version information
";
    alias arguments = getArguments!Cmd;
    putArguments(w, arguments);
}

private void putArguments(T)(T w, immutable Argument[] arguments)
        if (isOutputRange!(T, char))
{
    if (arguments.length == 0)
        return;
    w ~= "\nOPTIONS:\n";
    foreach (argument; arguments)
    {
        w ~= "    ";
        if (argument.short_.length > 0)
        {
            w ~= argument.short_;
            if (argument.long_.length > 0)
            {
                w ~= ", ";
            }
        }
        if (argument.long_.length > 0)
        {
            w ~= argument.long_;
        }
        w ~= " <";
        w ~= argument.fieldName;
        w ~= ">\n";
    }
}

unittest
{
    @command("example", "An example of structopt usage") struct Opt
    {
        @argument!(short_, long_) string name;
        @argument!(short_('o'), long_) string output;
        @argument!(short_('d')) string diff;
        @argument!(long_) string input;
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

OPTIONS:
    -n, --name <name>
    -o, --output <output>
    -d <diff>
    --input <input>
`;
    assert(w.data == expected, w.data);
}
