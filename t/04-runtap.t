#our @*MODULES = <
require Test::ATestML::TAP ;

=begin ATestML

{ 
  a1 != b1
  a2 == b2
}

=== test-1
--- a1: 1
--- b1: 2

=== test-2
--- a2: 1
--- b2: 1

=end ATestML

# vim: ft=perl6
