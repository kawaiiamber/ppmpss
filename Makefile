# vim: ts=4 sw=4 noet cc=80

.POSIX:

# install variables
DESTDIR =
PREFIX  = /usr/local

# build rules
ppmpss:
clean:
	@rm -f ppmpss

# install rules
install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp ppmpss $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/ppmpss
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/ppmpss

.SUFFIXES: .sh
.sh:
	cp $< $@
	chmod +x $@
