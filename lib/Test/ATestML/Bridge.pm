class Test::ATestML::Bridge ;

our sub trim(Str $a) { $a.trim() }
our sub perl($a)     { $a.perl   }
our sub cont(Str $a) { $a.subst( rx/ \\ \n \h* /, '', :g ) }

# vim:ft=perl6
