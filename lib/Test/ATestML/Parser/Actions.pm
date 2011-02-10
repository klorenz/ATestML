# sub Point(*@args, *%args) { Test::ATestML::Point.new(|@args, |%args) }

use Test::ATestML::Classes ;

class Test::ATestML::Parser::Actions ;

method Call(:$name, :$args) { 
    Test::ATestML::Call.new(:$name, :$args)
}

method Assertion(:$name, :$args) { 
    Test::ATestML::Assertion.new(:$name, :$args)
}

method Point($name) { Test::ATestML::Point.new(:$name) }

method TOP($/) { make $<tests>.ast }

method tests($/) { 
    my @tests = $<test>».ast ;
    for $<table_test>».ast -> $table_tests { @tests.push(|$table_tests) }

    make Test::ATestML::TestSuite.new:
        fixture   => $<statement>».ast,
        testcases => @tests;
}

method table_test($/) {
    my $th := $<th>».Str».trim.list ;
    my @result;
    for $<tr>.list -> $tr {
        my $td = $tr<td>;
        my %data ;
        for 1 .. $th.elems-1 -> $i {
            %data{$th[$i]} = $td[$i].Str.trim
        }

        @result.push( Test::ATestML::TestCase.new(
            name => $td[0].Str.trim,
            data => %data ));
    }
    make @result;
}


method test($/) {
    make Test::ATestML::TestCase.new:
        name        => ~$<name>,
        description => ~$<description>,
        data        => $<test_data>».ast.hash;
}

method test_data($/) { make ~$<name> => ~$<data> }

method statement($/) {
    make $<assignment>.Bool ?? $<assignment>.ast !! $<assertion>.ast
}

method assignment($/) {
    make Test::ATestML::Assign.new:
        name       => ~$<ident>,
        expression => $<expression>.ast;
}

method assertion($/) {
    my $cmp := ~$<comparison>;
    my $map = { '==' => 'assert-equals', '!=' => 'assert-not-equals', 
                '~~' => 'assert-matches' };
    make $<fixture>.Bool 
             ?? self.Assertion(name => 'assert-fixture', args => [ $<fixture>.ast ])
             !! self.Assertion(name => $map{$cmp}, args => ($<expression>».ast).list)
}

method fixture($/) { make $<functional>.ast }

method call($/) { 
    make self.Call(name => ~$<ident>, args => $<args>.ast)
}

method _filter_to_call($_arg, $/) {
    my $arg = $_arg ;
    for $<filter>».ast {
        $arg = self.Call(name => .key, args => Array.new($arg, |.value))
    }
    $arg;
}

method filter($/) {
    make ~$<ident> => ($<args>.Bool ?? $<args>.ast !! []) ;
}

method filtered($/) {
    make $<call>.Bool ?? self._filter_to_call($<call>.ast, $/) 
                      !! self._filter_to_call(self.Point(~$<ident>), $/) ;
}

method functional($/) {
    make $<call>.Bool ?? $<call>.ast !! $<filtered>.ast
}

method args($/) { make $<expression>».ast }

method expression:sym<string>($/)     { make ~$/ }
method expression:sym<number>($/)     { make +$/ }
method expression:sym<functional>($/) { make $<functional>.ast }
method expression:sym<point>($/)      { make self.Point(~$<ident>) }

# vim:ft=perl6
