our @*MODULES = <MyTest> ;
require Test::ATestML::TAP ;

module MyTest ;

our sub my-equals($a, $b) {
    fail "$a != $b" unless $a == $b;
}


=begin ATestML

{
   !! my-equals(a, b)
}

=== test-1
--- a: foo
--- b: foo

=end ATestML

# vim: ft=perl6
