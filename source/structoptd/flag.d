module structoptd.flag;

@safe:

import structoptd.attribute;

import std.conv : to;
import std.typecons : Nullable;
import std.traits : getUDAs, TemplateArgsOf, isInstanceOf, getSymbolsByUDA;

/// Flag is an internal representation of the flag.
public struct Flag
{
    ///
    string short_;
    ///
    string long_;
    ///
    string fieldName;
}

/// Extract @flag attributed fields.
public Flag[] getFlags(T)() if (isOption!T)
{
    Flag[] flags;
    static foreach (memberName; getSymbolsByUDA!(T, flag))
    {
        flags ~= parseFlagAttribute!(memberName.stringof, T);
    }
    return flags;
}

unittest
{
    @structopt struct Test
    {
        @flag!(short_) string shortFlag;
        @flag!(short_, long_) string bothShortLong;
        bool shouldBeIgnored;
    }

    enum flags = getFlags!Test;
    static assert(flags == [
            Flag("s", null, "shortFlag"),
            Flag("b", "bothShortLong", "bothShortLong"),
            ]);
}

private Flag parseFlagAttribute(alias memberName, T)() if (isOption!T)
{
    alias FlagOptions = TemplateArgsOf!(getUDAs!(__traits(getMember, T, memberName), flag)[0]);
    Flag f = {fieldName: memberName};
    static foreach (opt; FlagOptions)
    {
        static if (is(opt : long_))
        {
            f.long_ = memberName;
        }
        else static if (is(typeof(opt) : long_))
        {
            f.long_ = opt.name;
        }
        else static if (is(opt : short_))
        {
            f.short_ = memberName[0].to!string;
        }
        else static if (is(typeof(opt) : short_))
        {
            f.short_ = opt.name.to!string();
        }
    }
    return f;
}

unittest
{
    @structopt struct Test
    {
        @flag!short_ string shortFlagWithDefault;
        @flag!long_ string longFlagWithDefault;
        @flag!(short_('x')) string shortFlag;
        @flag!(long_("long")) string longFlag;
    }

    static assert(parseFlagAttribute!("shortFlagWithDefault", Test) == Flag("s",
            null, "shortFlagWithDefault"));
    static assert(parseFlagAttribute!("longFlagWithDefault", Test) == Flag(null,
            "longFlagWithDefault", "longFlagWithDefault"));
    static assert(parseFlagAttribute!("shortFlag", Test) == Flag("x", null, "shortFlag"));
    static assert(parseFlagAttribute!("longFlag", Test) == Flag(null, "long", "longFlag"));
}
