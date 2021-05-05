module structoptd.argument;

@safe:

import structoptd.attribute;

import std.format : format;
import std.conv : to;
import std.typecons : Nullable, nullable;
import std.traits : getUDAs, TemplateArgsOf, isInstanceOf, getSymbolsByUDA;

public struct Arguments
{
    Argument[] flags;
    Argument[] options;
    Argument[] positionalArguments;
}

/// Argument is an internal representation of the argument.
public struct Argument
{
    ///
    Nullable!string short_;
    ///
    Nullable!string long_;
    ///
    string fieldName;
    /// true if the argument does not take values. (e.g. -v)
    bool isFlag;

    /// true if the argument is a positional.
    bool isPositional() const
    {
        return (short_.get("") == "") && (long_.get("") == "");
    }

    /// true if the argument take values as option.
    bool isOption() const
    {
        return !isFlag && !isPositional;
    }
}

/// Extract @argument attributed fields.
public Arguments getArguments(T)() if (isCommand!T)
{
    Arguments arguments;
    static foreach (memberName; getSymbolsByUDA!(T, argument))
    {
        {
            const arg = parseArgumentAttribute!(memberName.stringof, T);
            if (arg.isFlag)
            {
                arguments.flags ~= arg;
            }
            else if (arg.isOption)
            {
                arguments.options ~= arg;
            }
            else if (arg.isPositional)
            {
                arguments.positionalArguments ~= arg;
            }
            else
            {
                assert(false, "unreachable");
            }
        }
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
    static assert(arguments.options == [
            Argument("-s".nullable, Nullable!string.init, "shortArgument"),
            Argument("-b".nullable, "--bothShortLong".nullable, "bothShortLong"),
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
        f.isFlag = is(typeof(__traits(getMember, T.init, memberName)) : bool);
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
        @argument!short_ bool verbose;
    }

    static assert(parseArgumentAttribute!("shortArgumentWithDefault",
            Test) == Argument("-s".nullable, Nullable!string.init, "shortArgumentWithDefault"));
    static assert(parseArgumentAttribute!("longArgumentWithDefault", Test) == Argument(Nullable!string.init,
            "--longArgumentWithDefault".nullable, "longArgumentWithDefault"));
    static assert(parseArgumentAttribute!("shortArgument",
            Test) == Argument("-x".nullable, Nullable!string.init, "shortArgument"));
    static assert(parseArgumentAttribute!("longArgument",
            Test) == Argument(Nullable!string.init, "--long".nullable, "longArgument"));
    static assert(parseArgumentAttribute!("verbose",
            Test) == Argument("-v".nullable, Nullable!string.init, "verbose", true));
}
