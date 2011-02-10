use Test;

plan 5 ;

use Test::ATestML::Parser::Grammar;
use Test::ATestML::Parser::Actions;

sub aligned($string) {
    return $string if $string !~~ m{ ^ \\ \n $<indent>=[ \h* ] };
    my $indent = $<indent>;
    $string.subst( rx/ ^ \\ \n /,    ''     
          ).subst( rx/ ^^ $indent /, '', :g 
          ).subst( rx/ \h+ $ /, '',
          ).subst( rx/ \\ \n \h* /,  '', :g
          );
}

sub parse_ok(Str $m, Str $I, Str $E, :$debug ) is export(:DEFAULT) {
    my $now = now.to-posix[0];
    my $P = Test::ATestML::Parser::Grammar.new();
    my $actions = Test::ATestML::Parser::Actions.new();
    my $O = $P.parse(aligned($I), :$actions) ;

    diag $O.perl if $debug;

    ok($O.ast.perl.trim eq aligned($E).trim, aligned($m)) or 
       diag("--- input:\n" ~ aligned($I) ~ 
            "--- output:\n" ~ $O.ast.perl ~ "\n" ~
            "--- expected:\n" ~ aligned($E)) ;
    diag "took " ~ (now.to-posix[0] - $now) ~ "s";
}



parse_ok
   "test-1",
   "=== test1\n",
   '\
    Test;ATestML;TestSuite.new(\
        fixture => (), \
        testcases => [Test;ATestML;TestCase.new(\
            name => "test1", data => {})], \
        modules => ["Test::ATestML::Runner::Bridge", \
                    "Test::ATestML::Bridge"])
   ';

parse_ok
   "test-2",
   '\
    %ATestML 0.1
    { a == b }
    === test2
    --- a: a
    --- b: a
   ',
   '\
    Test;ATestML;TestSuite.new(\
        fixture => (\
            Test;ATestML;Assertion.new(\
                name => "assert-equals", \
                args => (\
                    Test;ATestML;Point.new(name => "a"), \
                    Test;ATestML;Point.new(name => "b")))), \
        testcases => [\
            Test;ATestML;TestCase.new(\
                name => "test2", \
                data => {"a" => "a", "b" => "a"})], \
        modules => [\
            "Test::ATestML::Runner::Bridge", "Test::ATestML::Bridge"])
   ';

parse_ok
   'test-3',
   '\
    { a == b }
    ^ foo ^ a ^ abc ^
    | bar | x | y   |
    | hel | 1 | 2   |
   ',
   '\
    Test;ATestML;TestSuite.new(\
        fixture => (\
            Test;ATestML;Assertion.new(\
                name => "assert-equals", \
                args => (\
                    Test;ATestML;Point.new(name => "a"), \
                    Test;ATestML;Point.new(name => "b")))), \
        testcases => [\
            Test;ATestML;TestCase.new(\
                name => "bar", \
                data => {"a" => "x", "abc" => "y"}), \
            Test;ATestML;TestCase.new(\
                name => "hel", \
                data => {"a" => "1", "abc" => "2"})], \
        modules => [\
            "Test::ATestML::Runner::Bridge", "Test::ATestML::Bridge"])
   ';

parse_ok
   'test-4',
   '\
    {
       !! parse-able(x)
    }
    ^ name ^ x ^
    |  a   | b |
   ',
   '\
    Test;ATestML;TestSuite.new(\
        fixture => (\
            Test;ATestML;Assertion.new(\
                name => "assert-fixture", \
                args => [\
                    Test;ATestML;Call.new(\
                        name => "parse-able", \
                        args => Test;ATestML;Point.new(name => "x"))])), \
        testcases => [\
            Test;ATestML;TestCase.new(\
                name => "a", data => {"x" => "b"})], \
        modules => [\
            "Test::ATestML::Runner::Bridge", "Test::ATestML::Bridge"])
   ';

parse_ok
   'test-5',
   '\
    {
       !! parse-able(x).fixture()
    }
    ^ name ^ x ^
    |  a   | b |
   ',
   '\
    Test;ATestML;TestSuite.new(\
        fixture => (\
            Test;ATestML;Assertion.new(\
                name => "assert-fixture", \
                args => [\
                    Test;ATestML;Call.new(\
                        name => "fixture", \
                        args => [\
                            Test;ATestML;Call.new(\
                                name => "parse-able", \
                                args => Test;ATestML;Point.new(name => "x")\
        )])])), \
        testcases => [\
            Test;ATestML;TestCase.new(name => "a", data => {"x" => "b"})], \
        modules => [\
            "Test::ATestML::Runner::Bridge", "Test::ATestML::Bridge"])
   ';

# vim: ft=perl6
