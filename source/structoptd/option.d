module structoptd.option;

@safe:

import structoptd.attribute;

import std.format : format;
import std.conv : to;
import std.typecons : Nullable;
import std.traits : getUDAs, TemplateArgsOf, isInstanceOf, getSymbolsByUDA;

/// Option is an internal representation of the option.
public struct Option
{
    ///
    string short_;
    ///
    string long_;
    ///
    string fieldName;
}

/// Extract @option attributed fields.
public Option[] getOptions(T)() if (isCommand!T)
{
    Option[] options;
    static foreach (memberName; getSymbolsByUDA!(T, option))
    {
        options ~= parseOptionAttribute!(memberName.stringof, T);
    }
    return options;
}

unittest
{
    @command struct Test
    {
        @option!(short_) string shortOption;
        @option!(short_, long_) string bothShortLong;
        bool shouldBeIgnored;
    }

    enum options = getOptions!Test;
    static assert(options == [
            Option("-s", null, "shortOption"),
            Option("-b", "--bothShortLong", "bothShortLong"),
            ]);
}

private Option parseOptionAttribute(alias memberName, T)() if (isCommand!T)
{
    alias Options = TemplateArgsOf!(getUDAs!(__traits(getMember, T, memberName), option)[0]);
    Option f = {fieldName: memberName};
    static foreach (opt; Options)
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
        @option!short_ string shortOptionWithDefault;
        @option!long_ string longOptionWithDefault;
        @option!(short_('x')) string shortOption;
        @option!(long_("long")) string longOption;
    }

    static assert(parseOptionAttribute!("shortOptionWithDefault",
            Test) == Option("-s", null, "shortOptionWithDefault"));
    static assert(parseOptionAttribute!("longOptionWithDefault",
            Test) == Option(null, "--longOptionWithDefault", "longOptionWithDefault"));
    static assert(parseOptionAttribute!("shortOption", Test) == Option("-x", null, "shortOption"));
    static assert(parseOptionAttribute!("longOption", Test) == Option(null, "--long", "longOption"));
}
