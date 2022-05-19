# vim: ts=4 sw=4 noet cc=80

.POSIX:

# install variables
DESTDIR =
PREFIX  = /usr/local

# build rules
ppmpss:
clean:
	@rm -f ppmpss
	@rm -rf repos

# install rules
install:
	@echo "Installing binary..."
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp ppmpss $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/ppmpss
	@echo "Installing man page..."
	mkdir -p $(DESTDIR)$(PREFIX)/man/man1
	cp ppmpss.1 $(DESTDIR)$(PREFIX)/man/man1
	chmod 644 $(DESTDIR)$(PREFIX)/man/man1/ppmpss.1
	@echo "Installing default config..."
	mkdir -p $(DESTDIR)/etc/ppmpss
	cp ppmpss.rc $(DESTDIR)/etc/ppmpss
	chmod 644 $(DESTDIR)/etc/ppmpss/ppmpss.rc
uninstall:
	@echo "Uninstalling ppmpss..."
	rm -f $(DESTDIR)$(PREFIX)/bin/ppmpss
	rm -f $(DESTDIR)$(PREFIX)/man/man1/ppmpss.1
	rm -rf $(DESTDIR)/etc/ppmpss

# suffix rules
.SUFFIXES: .sh
.sh:
	cp $< $@
	chmod +x $@
