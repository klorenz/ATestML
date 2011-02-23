use v6;

use Test::ATestML::Bridge ;
use Test::ATestML::Parser ;

use Test ;

class Test::ATestML::Runner::Bridge is Test::ATestML::Bridge ;

our sub assert-equals($a, $b, $test?) {
    ok $a.Str eq $b.Str, $test or diag "assert-equals: $a ne $b" ;
}

our sub assert-not-equals($a, $b, $test) {
    ok $a ne $b, $test or diag "assert-not-equals: $a eq $b" ;
}

our sub assert-matches($a, $b, $test) {
    ok $a ~~ $b, $test or diag "assert-matches: $a !~~ $b"
}

our sub assert-fixture($function, $fixture-name, $test) {
    try {
        $function();
        ok True, $test ;
    }
    if ($!) {
        ok False, $test
        or diag "assert-fixture: $fixture-name failed:\n" ~ 
           Perl6::BacktracePrinter.backtrace_for($!.exception);
    }
        
    ##CATCH {
        #ok False, $test 
        #or diag "assert-fixture: $fixture-name failed:\n" ~ $!.Str ;
    #}
}

our sub assert-true($function, $fixture-name, $test) {
    ok $function(), $test or diag "assert-true: $fixture-name failed\n" ;
}

our sub assert-false($function, $fixture-name, $test) {
    ok !$function(), $test or diag "assert-false: $fixture-name failed\n" ;
}


class Test::ATestML::Runner::TAP ;

has @.files    = [] ;
has @.fixtures = [] ;
#has @.bridge-assert => (-> $thing { $thing ~~ Test::STestML::Bridge }) ;
has @.bridge-path   = [ "." ] ;

method run(@modules?) {
    for @.files -> $file {
        my $suite := Test::ATestML::Parser::parse-file($file) ;
        $suite.run(@modules) ;
    }
}
# vim:ft=perl6
