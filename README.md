# ppmpss
Portable Package Manager made in (mostly) POSIX Shell Script (ppmpss) is exactly as it says. This is the successor to my old project: neko. Some key differences:
* There will be SOME non-POSIX things.
* This is intended to be federated and non-central
* More automation for maintaining packages

## Non-POSIX things
Before, it was intended to write an HTTP-GET method, TLS library, Huffman / LZ77 decompressor (e.g. .gzip), etc all in POSIX shell script. While this is certainly possible, it was taking up too much time away from actually developing a package manager. Instead, using curl and standard decompression libraries, while not POSIX, will make development much faster. With that in mind, it's still my intention to make this as portable as possible.

## Federated packages
This repo does not come with any packages. Instead, it is simply a configuration setting of which repo to use for this package manager. It is intended and encouraged for people to make their own repository of templates for packages.

## More automation
Since everyone is encouraged to maintain their own repo (though they may use the default if they like), I intend to build tools into ppmpss that make that goal easier. One example is automatic update-checking. Scan through the installed packages and their dependencies and check the sites for updates; use a treeshaking-like method to see if there's no breakge (e.g. a package that's "too new") back and forwards until the most up-to-date and working versions are found.

# Build System
While I can just make ppmpss.sh and mark it executable on install to `$(DESTDIR)$(PREFIX)/bin`, POSIX make seems to have a workflow for shell scripts. In `make (1p)`, specifying the `.POSIX:` rule also garuntees the following:
```
.SUFFIXES: .sh

.sh:
	cp $< $@
	chmod a+x $@
```
among other things, as well. I named it `main.sh` as there's already `ppmpss.rc` and `ppmpss.1`.

# LICENSE
None yet, do whatever / feel free to contribute. Plan to use either MIT or GPL-3 (or later), though I am open to changing my mind.
