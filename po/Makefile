#!/usr/bin/make -f

PO := $(wildcard *.po)
MO := installer-cli.mo

all: $(PO)

%.po: FORCE
	mkdir  -p locale/$(@:.po=)/LC_MESSAGES
	msgfmt -o locale/$(@:.po=)/LC_MESSAGES/$(MO) $@
FORCE:

clean:
	$(RM) -r locale

distclean: clean

