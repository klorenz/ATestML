module Test::ATestML::Parser ;

use Test::ATestML::Parser::Grammar ;
use Test::ATestML::Parser::Actions ;

our sub parse-file($filename) {
    my $G := Test::ATestML::Parser::Grammar.new();
    my $actions := Test::ATestML::Parser::Actions.new();
    my $result := Mu ;
    given open $filename, :r {
        $result := $G.parse(.slurp, :$actions).ast ;
        .close;
    }
    return $result;
}

our sub parse($string) {
    my $G := Test::ATestML::Parser::Grammar.new();
    my $actions := Test::ATestML::Parser::Actions.new();
    return $G.parse($string, :$actions).ast ;
}

# vim:ft=perl6
