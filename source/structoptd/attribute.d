module structoptd.attribute;

@safe:

import std.array : appender;
import std.format : format;
import std.meta : Filter;
import std.traits : hasUDA, getUDAs, isInstanceOf, TemplateArgsOf;

/// command is used as UDA that describe name and usage of the application.
public struct command
{
    /// program name
    string name;
    /// version of the program
    string version_ = "";
    /// description of the program
    string about = "";
}

/// Return true if the type T has a command attribute.
public enum isCommand(T) = hasUDA!(T, command);
/// Return a command attribute.
public enum getCommand(T) = getUDAs!(T, command)[0];

public struct argument(T...)
{
}

/// short_ is used as UDA that enables short style syntax.
public struct short_
{
    /// The character for the flag.
    /// By default, the first character of the option field is used as a flag.
    char name;
}

/// long_ is used as UDA that enables long style syntax.
public struct long_
{
    /// The name for the flag.
    /// By default, the name of the option field is used as a flag.
    string name = "";
}
