require Test::ATestML::TAP ;

=begin ATestML

{ a.trim == b.trim }

=== test-1
--- a: 1
--- b: 1

=== test-2
--- a
foo bar
--- b
foo bar

=== test-3
--- c: x
--- d: y

=end ATestML
