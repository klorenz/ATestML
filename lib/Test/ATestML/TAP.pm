module Test::ATestML::TAP ;

use Test::ATestML::Parser ;
use Test::ATestML::Runner::TAP ;

sub runtap {
    my @modules = defined(@*MODULES) ?? @*MODULES !! () ;
    given open $*PROGRAM_NAME, :r {
        my $string := .slurp.subst( rx/ ^ .*? ^^ '=begin ATestML' \h* \n /, ''
                           ).subst( rx/ ^^ "=end ATestML" .* $ /, '');

        my $suite := Test::ATestML::Parser::parse($string);
        say $suite.perl;
        $suite.run(@modules);
        .close;
    }
}

runtap();

=begin pod

=head1 DESCRIPTION

This module is for easy use of ATestML in perl6 context. Create a file
mytest.t and write following

  require Test::ATestML::TAP ;

  =begin ATestML

  TEST Specification goes here!!!

  =end

If you want to define extra modules:

  our @*MODULES = <First::Module Second::Module>;
  require Test::ATestML::TAP;

  module First::Module ;

  ...

  module Second::Module ;

  ...

  =begin ATestML

  =end ATestML


=end pod

# vim: ft=perl6
