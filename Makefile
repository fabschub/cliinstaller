#!/usr/bin/make -f
all:
	$(MAKE) -C po $@

clean:
	$(MAKE) -C po $@

distclean: clean
