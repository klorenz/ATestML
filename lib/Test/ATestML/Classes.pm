use v6;

class Test::ATestML::Point { 
    has $.name ;
}

class Test::ATestML::Assign {
    has $.name ;
    has $.expression ;

    method points() {
        given $.expression {
            when (Test::ATestML::Point) { return [ $.expression ]; }
            when (Test::ATestML::Call)  { return $.expression.points(); }
            when * { return Array.new(); }
        }
    }

    method applies($test, $context) { return Bool::True ; }

    method evaluate($test, $context, @modules) {
        my $doit := True;
        for $.points { 
            $doit := False if !$test.exists{$_} && !$context.exists{$_};
        }

        return 0 if !$doit;

        given $.expression {
            when (Test::ATestML::Point) {
                $context{$.name} := $test.data{$.expression.name}
            }
            when (Test::ATestML::Call) {
                $context{$.name} := 
                    $.expression.evaluate($test, $context, @modules)
            }
            when * {
                $context{$.name} := $.expression
            }
        }

        return 1;
    }
}

use Test;

class Test::ATestML::TestSuite { 
    has $.fixture   = [];
    has $.testcases = [];
    has @.modules   = <Test::ATestML::Runner::Bridge Test::ATestML::Bridge>;

    method run(@modules?) {
        my $context = {};
        my @mods = List.new(|@modules, |@.modules);

        # count tests
        my $test-count = 0;
        for $.testcases -> $test {
            for $.fixture -> $statement {
                if $statement.applies($test, $context) {
                    $test-count++ ;
                }
            }
        }

        # run tests
        plan $test-count ;
        for $.testcases -> $test {
            for $.fixture -> $statement {
                if $statement.applies($test, $context) {
                    $statement.evaluate($test, $context, @mods);
                }
            }
        }
    }
}

class Test::ATestML::TestCase { 
    has $.name = [];
    has $.data = {};
}

class Test::ATestML::Call {
    has $.name   = Any ;
    has $.args   = []  ;

    method points() {
        my @result ;
        for $.args {
            when Test::ATestML::Point {
                @result.push($_);
            }
            when Test::ATestML::Call {
                @result.push(.points)
            }
        }
        @result;
    }

    method applies($test, $context) {
        my $doit := True;
        for $.points { 
            $doit := False if !$test.data.exists(.name); 
        }
        return $doit;
    }

    method _get_function(@modules) {
        my $function;
        for @modules -> $bridge {
            eval "need $bridge ;";
            my $func = "&$bridge" ~ "::" ~ "$.name";
            $function = eval $func ;
            last if $function ;
        }
        die "could not get function $.name in " ~ @modules.perl if !$function;
        $function;
    }

    method _get_args($args, $test, $context, @modules) {
        my @args;
        for $args.list {
            when Test::ATestML::Point {
                my $data := $test.data;
                if    $context.exists(.name) {
                    @args.push($context{.name});
                }
                elsif $data.exists(.name) {
                    @args.push($data{.name});
                }
            }
            when Test::ATestML::Call {
                @args.push(.evaluate($test, $context, @modules))
            }
            default {
                @args.push($_);
            }
        }
        @args;
    }

    method evaluate($test, $context, @modules) {
        #eval "need $module_name"
        #my $module = eval($module_name);
        #die unless

        my $function = self._get_function(@modules);
        my @args     = self._get_args($.args, $test, $context, @modules);

        $function(|@args);
    }

}

class Test::ATestML::Assertion is Test::ATestML::Call {
    method evaluate($test, $context, @modules) {
        my @args ;
        if $.name eq 'assert-fixture' {
            # if filtered handle different !!!
            my $call := $.args[0];
            @args.push( -> { $call.evaluate($test, $context, @modules) },
                        $call.name )
        }
        else
        {
            @args.push(self._get_args($.args, $test, $context, @modules));
        }

        my $function = self._get_function(@modules);

        @args.push($test.name);

        $function(|@args);
    }
}

# vim: ft=perl6
