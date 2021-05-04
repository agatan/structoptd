module structoptd.help;

@safe:

import std.range : isOutputRange;
import std.algorithm : filter, joiner;
import std.format : format;

import structoptd.attribute;
import structoptd.option;

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
    alias options = getOptions!Cmd;
    putOptions(w, options);
}

private void putOptions(T)(T w, immutable Option[] options)
        if (isOutputRange!(T, char))
{
    if (options.length == 0)
        return;
    w ~= "\nOPTIONS:\n";
    foreach (option; options)
    {
        w ~= "    ";
        if (option.short_.length > 0)
        {
            w ~= option.short_;
            if (option.long_.length > 0)
            {
                w ~= ", ";
            }
        }
        if (option.long_.length > 0)
        {
            w ~= option.long_;
        }
        w ~= " <";
        w ~= option.fieldName;
        w ~= ">\n";
    }
}

unittest
{
    @command("example", "An example of structopt usage") struct Opt
    {
        @option!(short_, long_) string name;
        @option!(short_('o'), long_) string output;
        @option!(short_('d')) string diff;
        @option!(long_) string input;
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
