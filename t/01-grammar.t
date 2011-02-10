use Test;

use Test::ATestML::Parser::Grammar ;

plan 12;

# remove indentation of first line from all lines if starts with \\ \n
sub aligned($string) {
    return $string if $string !~~ m{ ^ \\ \n $<indent>=[ \h* ] };
    my $indent = $<indent>;
    $string.subst( rx/ ^ \\ \n /,    ''     
          ).subst( rx/ ^^ $indent /, '', :g 
          ).subst( rx/ \h+ $ /, '',
          ).subst( rx/ \\ \n \h* /,  '', :g
          );
}

sub parsable(Str $m, Str $I) {
    my $now = now.to-posix[0];
    my $P = Test::ATestML::Parser::Grammar.new();
    my $O = $P.parse(aligned($I));
    ok $O ~~ aligned($I), $m or diag aligned($I).perl ~ "\n" ~ $O.perl;
    diag "took " ~ (now.to-posix[0] - $now) ~ "s";
}

class DiagActions {
    multi sub __(@lines) { return @lines.map({"| $_\n"}).join(""); }
    multi sub __($lines) { return (~$lines).lines.map({"| $_\n"}).join(""); }

    method TOP($/) { make $<tests>.ast }
    method tests($/) { make ([~] $<statement>».ast) ~ ([~] $<test>».ast) ~ 
        ([~] $<table_test>».ast) }

    method statement($/) {
        make $<assignment>.Bool ?? $<assignment>.ast !! $<assertion>.ast ;
    }

    method assignment($/) {
        make "assign: " ~ $<ident> ~ '=' ~ $<expression>.ast ;
    }

    method test($/)  { 
        make 
        ("-" x 30) ~ "\n" ~
        "test: " ~ (~$<name>).perl ~ "\n" ~ 
        "desc: " ~ (~$<description>).perl ~ "\n" ~ 
        ([~] $<test_data>».ast);
    }
    method test_data($/) { make "* " ~ $<name> ~ ": " ~ 
        (~$<data>).perl ~ "\n" 
    }

    method table_test($/) {
        my $th := $<th>».Str».trim ;
        my $result = '';
        for $<tr>.list -> $tr {
            my $td := $tr<td> ;
            $result ~= ("-" x 30) ~ "\n" ;
            $result ~= "test: $td[0]\n" ;
            for 1 .. $th.elems-1 -> $i {
                $result ~= '* ' ~ $th[$i] ~ ": " ~ $td[$i].Str.trim.perl ~ "\n";
            }
        }
        make $result;
    }

    method assertion($/) {
        make "assert: " ~ (
             $<fixture>.Bool && $<fixture>.ast.trim ||
             $<expression>[0].ast ~ " " ~ $<comparison> ~ " " ~ 
             $<expression>[1].ast) 
             ~ "\n" ;
    }

    method fixture($/) {
        make $<functional>.ast ;
    }

    method expression:sym<string>($/) {
        make (~$/).perl;
    }

    method expression:sym<number>($/) {
        make ~$/;
    }

    method expression:sym<functional>($/) {
        make $<functional>.ast;
    }

    method expression:sym<point>($/) {
        make ~$<ident>;
    }

    method functional($/) {
        make ~$/;
    }

}

sub parse_ok(Str $m, Str $I, Str $E, :$debug ) is export(:DEFAULT) {
    my $now = now.to-posix[0];
    my $P = Test::ATestML::Parser::Grammar.new();
    my $actions = DiagActions.new();
    my $O = $P.parse(aligned($I), :$actions);

    diag $O.perl if $debug;

    ok ~($O.ast) eq aligned($E), aligned($m) or 
       diag "--- input:\n" ~ aligned($I) ~ 
            "--- output:\n" ~ $O.ast ~ 
            "--- expected:\n" ~ aligned($E) ~ $O.ast.perl ~ "\n" ~ aligned($E).perl;
    diag "took " ~ (now.to-posix[0] - $now) ~ "s";
}

parsable "empty-1", "";
parsable "empty-2", "\n";
parsable "empty-3", "\n  \n";

parsable 
   'test-1',
   '\
    Hello World

    === test1
    --- input: data
    --- output: other data

    === test3
    --- input
    data
    --- output
    other data
    ---
   ';

parsable 
   'test-2',
   '\
    === test1
    === test2
   ';

parse_ok 
   'test-3',
   '\
    === test1
    --- input: data

    --- input2: data
    Hier ist noch ein Kommentar

    === test2
    --- input
    data
    ---
    Hier ist noch ein Kommentar

    Und noch eins

    === test3
   ',
   '\
    ------------------------------
    test: "test1"
    desc: ""
    * input: "data"
    * input2: "data"
    ------------------------------
    test: "test2"
    desc: ""
    * input: "data\n"
    * : ""
    ------------------------------
    test: "test3"
    desc: ""
   ';

parsable 
   'test-4',
   '\
     foo == bar
    === test1
    === test2
   ';

parse_ok
   'test-5',
   '\
    Here is a test
    { foo == bar }
    === test1
    === test2
   ',
   '\
    assert: foo == bar
    ------------------------------
    test: "test1"
    desc: ""
    ------------------------------
    test: "test2"
    desc: ""
   ';

# how to specify setup and teardown actions?

parse_ok
   'test-6',
   '\
    Here is a test
    {
      foo == bar         # here foo has point input
      !! testcase(foo, bar) 
    }
    === test1
    === test2
   ',
   '\
    assert: foo == bar
    assert: testcase(foo, bar)
    ------------------------------
    test: "test1"
    desc: ""
    ------------------------------
    test: "test2"
    desc: ""
   ';

parse_ok
    'test-7',
    '\
     { a == b }
     ^ name ^ a ^ b ^
     | 1st  | 1 | 2 |
     | 2nd  | 3 | 4 |
    ',
    '\
     assert: a == b
     ------------------------------
     test: 1st  
     * a: "1"
     * b: "2"
     ------------------------------
     test: 2nd  
     * a: "3"
     * b: "4"
    ';
     
parse_ok
    'test-8',
    '\
     { !! foo(x) }
     ^ name ^ x ^
     | 1st  | 1 |
    ',
    '\
     assert: foo(x)
     ------------------------------
     test: 1st  
     * x: "1"
     ';

parse_ok
    'test-9',
    '\
     { !! foo(x).bar(y) }
     ^ name ^ x ^
     | 1st  | 1 |
    ',
    '\
     assert: foo(x).bar(y)
     ------------------------------
     test: 1st  
     * x: "1"
     ';


# Bridge: 

done;

# vim:ft=perl6
