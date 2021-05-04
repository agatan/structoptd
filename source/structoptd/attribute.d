module structoptd.attribute;

@safe:

import std.array : appender;
import std.format : format;
import std.meta : Filter;
import std.traits : hasUDA, getUDAs, isInstanceOf, TemplateArgsOf;

/// structopt is used as UDA that describe name and usage of the application.
public struct structopt
{
    /// program name
    string name;
    /// version of the program
    string version_ = "";
    /// description of the program
    string about = "";
}

/// Return true if the type T has StructOpt attribute.
public enum isOption(T) = hasUDA!(T, structopt);
/// Return a StructOpt attribute.
public enum getStructOpt(T) = getUDAs!(T, structopt)[0];

/// dotfm 0.1.3
// USAGE:
// dotfm [OPTIONS] <SUBCOMMAND>
//
// FLAGS:
// -h, --help       Prints help information
// -V, --version    Prints version information
//
// OPTIONS:
// -p, --path <path>     [default: /Users/agatan/dotfiles]
//
// SUBCOMMANDS:
// clean     Clean symbolic links
// clone     Clone your dotfiles repository
// commit    Add all dirty files, then create a commit
// edit      Edit your files
// git       Execute git command in dotfiles directory
// help      Prints this message or the help of the given subcommand(s)
// link      Link dotfiles
// list      List target files
// status    Show dotfiles status
// sync      Sync local and remote dotfiles

string helpMessage(T)() if (isOption!T)
{
    auto w = appender!string();
    enum opt = getStructOpt!T;
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
    return w.data;
}

unittest
{
    @structopt("example", "An example of StructOpt usage") struct Opt
    {
        string name;
    }

    static assert(!is(typeof(parseArgs!int([]))));

    static assert(helpMessage!Opt == `example
USAGE:
example [OPTIONS]

FLAGS:
-h, --help      Prints help information
-V, --version   Prints version information
`, helpMessage!Opt);
}
