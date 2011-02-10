# %STestML
use v6;

grammar Test::ATestML::Parser::Grammar;

token TOP {
#    <statement>
#    <?DEBUG>
    ^ <tests> $
}

token tests {
    [ <?TEST_MARKER> <test>
    | <TEST_END_MARKER> \n
    | '{' <statement>* <.ws> '}' <.ws>
    | <?[^]> <table_test>
    | \N* \n 
    ]*
}

token table_test {
    [ '^' \h* $<th>=[ <![^]> \N ]+ ]+ '^' \h* \n
    <tr>*
}

token tr {
    [ '|' \h* $<td>=[ <![|]> \N ]+ ]+ '|' \h* \n
}

rule statement {
    <assignment> | <assertion>
}

rule assignment {
    <ident> '=' <expression>
}

rule assertion {
    [ 
    | <fixture>
    | <expression> <.ws> <comparison> <expression>
    ]
}

token fixture {
    [ '!!' ] # | '?!' | '!+' | '!-' ] Here some ideas for assertion-symbols
    <.ws> <functional>
}

token comparison {
   [ '==' | '!=' | '~~' ]
}

proto token expression { <...> }

token expression:sym<string> {
    # <string>
    # <ident> <filter>*
    '"' [ "\\\\" | "\\" '"' | <-[\\"]>* ] '"'
}

token ident {
    [ \w | '-' ]+
}

token expression:sym<number> {
    $<sign>=['-' | '+']? \d+ [ \. \d+ ]?
}

token expression:sym<functional> {
    <functional>
}

token expression:sym<point> {
    <ident>
}

token functional {
    <filtered> | <call>
}

rule call {
    <ident> [ '(' ')' | '(' <args> ')' ]
}

rule filtered {
      <call> <filter>+
    | <ident> <filter>+
}

rule filter {
    '.' <ident> [ '(' ')' | '(' <args> ')' ]?
}

rule args {
    <expression> ** ','
}

token ws {
    \s* [ '\\' \n \h* | '#' \N* \n ]?
}



token TEST_MARKER { '===' }
token TEST_DATA_MARKER { '---' }
token TEST_END_MARKER { '...' }

token test {
    <TEST_MARKER> \h+ $<name>=\N* \n

    $<description>=<test_lines>     # here should be able to define local assertions

    <test_data>*
}

token test_data {
    <TEST_DATA_MARKER> [ \n | \h+ 
    $<name>=[ <![:]> \N ]* 
    [
    | ':' \h+ $<data>=\N+ \n
      <test_lines>
    | \n $<data>=<test_lines>
    ]
    ]
}

token test_lines {
    [ <!TEST_DATA_MARKER> 
      <!TEST_MARKER>
      <!TEST_END_MARKER>
      \N* \n ]*
}

#rule statement {
    #|  <meta>
    #|  <function>
#}

rule meta {
    |   <meta_version>
    |   <meta_bridge>
}

rule meta_version {
    '%ATestML' $<version>=[ \d+ [ \. \d+ ]* ] # from now on parse this 
                                              # version's style
}

rule meta_bridge {
    '%Bridge' <bridge_name> <imports>+
}

#token { ^^ '%' 

# vim: ft=perl6
