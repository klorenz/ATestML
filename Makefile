# vim:noet:

# export PERL6LIB 

LIBDIRS = $(shell find lib -type d)
TESTDIRS = $(addsuffix /,$(shell find t -type d))

SOURCES = $(shell find lib -name "*.pm")
TARGETS = $(SOURCES:.pm=.pir)

PERL6_EXE = rakudo/perl6

implicit-pir.mak: $(SOURCES)
	>$@
	for i in $(LIBDIRS) ; do \
	    echo "$$i/%.pir: $$i/%.pm" >> $@ ;\
	    echo '\tPERL6LIB=lib $(PERL6_EXE) --target=pir --output=$$@ $$<' >>$@ ;\
	    echo >> $@ ;\
	done

include implicit-pir.mak

lib/Test/ATestML/Parser/Actions.pir: lib/Test/ATestML/Classes.pir

all: $(TARGETS)

test: $(TARGETS)
	PERL6LIB=lib prove --exec $(PERL6_EXE) $(TESTDIRS)

test-verbose: $(TARGETS)
	PERL6LIB=lib prove -v --exec $(PERL6_EXE) $(TESTDIRS)

perl6:
	PERL6LIB=lib rlwrap $(PERL6_EXE)

clean:
	find lib -name "*.pir" -exec rm '{}' \;

.PHONY: test test-verbose clean perl6
