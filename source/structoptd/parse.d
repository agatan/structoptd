module structoptd.parse;

import std.conv;
import std.range;
import std.stdio;
import std.format;
static import core.stdc.stdlib;

import structoptd.attribute;
import structoptd.argument;
import structoptd.help;

/// ParseException is a base exception about argument parsing.
public abstract class ParseException(T) : Exception if (isCommand!T)
{
    ///
    this(string msg = "", string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }

    ///
    void putVerboseMessage(U)(U w) const if (isOutputRange!(U, char))
    {
        w.put(msg);
        putUsage!T(w);
        w.put("\nFor more information, try '--help'\n");
    }

    ///
    string verboseMessage() const
    {
        auto w = appender!string;
        putVerboseMessage(w);
        return w.data;
    }

    /// Prints the exception to stderr and exits with a status of 1.
    void exit() const
    {
        putVerboseMessage(stderr.lockingTextWriter);
        core.stdc.stdlib.exit(1);
    }
}

///
public class HelpSpecifiedException(T) : ParseException!T
{
    override void putVerboseMessage(U)(U w) const if (isOutputRange!(U, char))
    {
        putHelpMessage!T(w);
    }
}

///
public class VersionSpecifiedException(T) : ParseException!T
{
    override void putVerboseMessage(U)(U w) const if (isOutputRange!(U, char))
    {
        putVersion!T(w);
    }
}

///
public class EmptyValueException(T) : ParseException!T
{
    ///
    this(string argument)
    {
        super(format!"The argment '%s' requires a value but none was supplied"(argument));
    }
}

///
public class MissingRequiredArgumentException(T) : ParseException!T
{
    ///
    this(string argument)
    {
        super(format!"The argment '%s' was not supplied"(argument));
    }
}

///
public class UnknownArgumentException(T) : ParseException!T
{
    ///
    this(string argument)
    {
        super(format!"Found argument '%s' which wasn't expected"(argument));
    }
}

/// Builds the struct from the arguments. Calls core.stdc.stdlib.exit if an exception occurs.
public T parseOrExit(T)(string[] argv) if (isCommand!T)
{
    try
    {
        return parseOrThrow!T(argv);
    }
    catch (ParseException!T ex)
    {
        ex.exit();
    }
}

/// Builds the struct from the arguments. Throw an exception on failure.
public T parseOrThrow(T)(string[] argv) if (isCommand!T)
{
    static immutable arguments = getArguments!T;
    T result;

    int index = 0;
    string[] remaining;
    loop: while (index < argv.length)
    {
        const arg = argv[index];
        index++;
        if (arg == "-h" || arg == "--help")
        {
            throw new HelpSpecifiedException!T();
        }
        if (arg == "-V" || arg == "--version")
        {
            throw new VersionSpecifiedException!T();
        }
        static foreach (flag; arguments.flags)
        {
            {
                if ((!flag.short_.isNull && arg == flag.short_.get)
                        || (!flag.long_.isNull && arg == flag.long_.get))
                {
                    __traits(getMember, result, flag.fieldName) = true;
                    continue loop;
                }
            }
        }
        static foreach (option; arguments.options)
        {
            {
                if ((!option.short_.isNull && arg == option.short_.get)
                        || (!option.long_.isNull && arg == option.long_.get))
                {
                    if (index >= argv.length)
                    {
                        throw new EmptyValueException!T(arg);
                    }
                    const value = argv[index];
                    index++;
                    alias DstType = typeof(__traits(getMember, result, option.fieldName));
                    __traits(getMember, result, option.fieldName) = value.to!DstType;
                    continue loop;
                }
            }
        }
        remaining ~= arg;
    }
    static foreach (i, posArg; arguments.positionalArguments)
    {
        {
            if (remaining.empty)
            {
                throw new MissingRequiredArgumentException!T(format!"<%s>"(posArg.fieldName));
            }
            alias DstType = typeof(__traits(getMember, result, posArg.fieldName));
            __traits(getMember, result, posArg.fieldName) = remaining.front.to!DstType;
            remaining.popFront;
        }
    }
    if (!remaining.empty)
    {
        throw new UnknownArgumentException!T(remaining.front);
    }
    return result;
}

/// ditto
unittest
{
    @command("example", "0.0.1", "about message")
    struct Example
    {
    }

    immutable result = parseOrThrow!Example([]);
    assert(result == Example());
}

/// ditto
unittest
{
    import std.exception : assertThrown;

    @command("example", "0.0.1", "about message")
    struct Example
    {
    }

    alias Expected = HelpSpecifiedException!Example;

    assertThrown!Expected(parseOrThrow!Example(["-h"]));
    assertThrown!Expected(parseOrThrow!Example(["--help"]));
    assertThrown!Expected(parseOrThrow!Example(["something", "-h"]));
    assertThrown!Expected(parseOrThrow!Example(["something", "-h", "--version"]));
}

/// ditto
unittest
{
    import std.exception : assertThrown;

    @command("example", "0.0.1", "about message")
    struct Example
    {
    }

    alias Expected = VersionSpecifiedException!Example;

    assertThrown!Expected(parseOrThrow!Example(["-V"]));
    assertThrown!Expected(parseOrThrow!Example(["--version"]));
    assertThrown!Expected(parseOrThrow!Example(["something", "-V"]));
    assertThrown!Expected(parseOrThrow!Example(["something", "-V", "--help"]));
}

/// ditto
unittest
{
    @command("example", "0.0.1", "about message")
    struct Example
    {
        @argument!(short_, long_) bool verbose;
    }

    assert(!parseOrThrow!Example([]).verbose);
    assert(parseOrThrow!Example(["-v"]).verbose);
    assert(parseOrThrow!Example(["--verbose"]).verbose);
}

/// ditto
unittest
{
    import std.exception : assertThrown;

    @command("example", "0.0.1", "about message")
    struct Example
    {
        @argument!(short_, long_) string output;
    }

    assert(parseOrThrow!Example(["-o", "out"]).output == "out");
    assert(parseOrThrow!Example(["--output", "out"]).output == "out");
    assertThrown!(EmptyValueException!Example)(parseOrThrow!Example(["--output"]));
}

/// ditto
unittest
{
    import std.exception : assertThrown;

    @command("example", "0.0.1", "about message")
    struct Example
    {
        @argument!() string input;
        @argument!() string output;
    }

    immutable example = parseOrThrow!Example(["input", "output"]);
    assert(example.input == "input");
    assert(example.output == "output");
    assertThrown!(MissingRequiredArgumentException!Example)(parseOrThrow!Example([
            ]));
    assertThrown!(MissingRequiredArgumentException!Example)(parseOrThrow!Example([
                "input"
            ]));
}

/// ditto
unittest
{
    import std.exception : assertThrown;

    @command("example", "0.0.1", "about message")
    struct Example
    {
    }

    assertThrown!(UnknownArgumentException!Example)(parseOrThrow!Example([
                "input", "output"
            ]));
}
