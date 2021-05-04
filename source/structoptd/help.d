module structoptd.help;

@safe:

import std.range : isOutputRange;
import std.algorithm : filter, joiner;
import std.format : format;

import structoptd.attribute;
import structoptd.flag;

/// putHelpMessage puts the help message of the command to the OutputRange.
public void putHelpMessage(Opt, T)(T w) if (isOption!Opt && isOutputRange!(T, char))
{
    enum opt = getStructopt!Opt;
    w ~= opt.name;
    if (opt.about != "")
    {
        w ~= format!" %s"(opt.about);
    }
    w ~= '\n';
    w ~= "USAGE:\n";
    w ~= format!"%s [OPTIONS]\n\n"(opt.name);
    w ~= "FLAGS:
    -h, --help      Prints help information
    -V, --version   Prints version information
";
    alias flags = getFlags!Opt;
    putOptions(w, flags);
}

private void putOptions(T)(T w, immutable Flag[] options)
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
    @structopt("example", "An example of structopt usage") struct Opt
    {
        @flag!(short_, long_) string name;
        @flag!(short_('o'), long_) string output;
        @flag!(short_('d')) string diff;
        @flag!(long_) string input;
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
