.POSIX:

SHELL   = /bin/sh
SRC     = main
BIN     = ppmpss
MAN     = $(BIN).1
CONF    = $(BIN).rc
PREFIX  = /usr/local
BINDIR  = $(DESTDIR)$(PREFIX)/bin
MANDIR  = $(DESTDIR)$(PREFIX)/share/man/man1
CONFDIR = $(DESTDIR)/etc/$(BIN)

$(BIN): $(SRC)
	mv $< $@

$(SRC):

clean:
	@rm -f $(BIN)

install:
	mkdir -p $(BINDIR) $(MANDIR) $(CONFDIR)
	cp $(BIN) $(BINDIR)
	cp $(MAN) $(MANDIR)
	cp $(CONF) $(CONFDIR)
	chmod 755 $(BINDIR)/$(BIN)
	chmod 644 $(MANDIR)/$(MAN) $(CONFDIR)/$(CONF)

uninstall:
	rm -rf $(BINDIR)/$(BIN) $(CONFDIR) $(MANDIR)/$(MAN)
