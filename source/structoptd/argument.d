module structoptd.argument;

@safe:

import structoptd.attribute;

import std.format : format;
import std.conv : to;
import std.typecons : Nullable;
import std.traits : getUDAs, TemplateArgsOf, isInstanceOf, getSymbolsByUDA;

/// Argument is an internal representation of the argument.
public struct Argument
{
    ///
    string short_;
    ///
    string long_;
    ///
    string fieldName;
}

/// Extract @argument attributed fields.
public Argument[] getArguments(T)() if (isCommand!T)
{
    Argument[] arguments;
    static foreach (memberName; getSymbolsByUDA!(T, argument))
    {
        arguments ~= parseArgumentAttribute!(memberName.stringof, T);
    }
    return arguments;
}

unittest
{
    @command struct Test
    {
        @argument!(short_) string shortArgument;
        @argument!(short_, long_) string bothShortLong;
        bool shouldBeIgnored;
    }

    enum arguments = getArguments!Test;
    static assert(arguments == [
            Argument("-s", null, "shortArgument"),
            Argument("-b", "--bothShortLong", "bothShortLong"),
            ]);
}

private Argument parseArgumentAttribute(alias memberName, T)() if (isCommand!T)
{
    alias Arguments = TemplateArgsOf!(getUDAs!(__traits(getMember, T, memberName), argument)[0]);
    Argument f = {fieldName: memberName};
    static foreach (opt; Arguments)
    {
        static if (is(opt : long_))
        {
            f.long_ = "--" ~ memberName;
        }
        else static if (is(typeof(opt) : long_))
        {
            f.long_ = "--" ~ opt.name;
        }
        else static if (is(opt : short_))
        {
            f.short_ = format!"-%s"(memberName[0]);
        }
        else static if (is(typeof(opt) : short_))
        {
            f.short_ = format!"-%s"(opt.name);
        }
    }
    return f;
}

unittest
{
    @command struct Test
    {
        @argument!short_ string shortArgumentWithDefault;
        @argument!long_ string longArgumentWithDefault;
        @argument!(short_('x')) string shortArgument;
        @argument!(long_("long")) string longArgument;
    }

    static assert(parseArgumentAttribute!("shortArgumentWithDefault",
            Test) == Argument("-s", null, "shortArgumentWithDefault"));
    static assert(parseArgumentAttribute!("longArgumentWithDefault",
            Test) == Argument(null, "--longArgumentWithDefault", "longArgumentWithDefault"));
    static assert(parseArgumentAttribute!("shortArgument", Test) == Argument("-x", null, "shortArgument"));
    static assert(parseArgumentAttribute!("longArgument", Test) == Argument(null, "--long", "longArgument"));
}
