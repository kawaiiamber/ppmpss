#!/bin/sh

# Initialize empty vars.
for var in PKGSDIR REPO REPO_BRANCH; do
	eval $var=
done

# Initialize flags.
for flag in HELP SKIP WARNING; do
	eval $flag=false
done

# Read config if it exists.
# ORDER: global, local, current directory
[ -f /etc/ppmpss/ppmpss.rc ] && . /etc/ppmpss/ppmpss.rc
[ -f ${XDG_CONFIG_HOME:-~/.config}/ppmpss/ppmpss.rc ] &&
	. ${XDG_CONFIG_HOME:-~/.config}
[ -f ./ppmpss.rc ] && . ./ppmpss.rc

# Store non-option arguments.
args=
while [ $# -gt 0 ]; do
	case $1 in
	--[Pp]kgs_[Dd]ir=* | --[Pp]kgs_[Dd]irectory=*) PKGSDIR=${1#*=};;
	--[Pp]kgs_[Dd]ir | --[Pp]kgs_[Dd]irectory) PKGSDIR=$2; shift;;
	--[Rr]epo=* | --[Rr]epository=*) REPO=${1#*=};;
	--[Rr]epo | --[Rr]epository) REPO=$2; shift;;
	-[Hh] | --[Hh]elp) HELP=true;;
	-[Yy] | --[Yy]es) SKIP=true;;
	--) break;;
	-*) printf "Unknown option: %s\n" "$1"; exit 1;;
	*) args="$args $1";;
	esac
	shift
done
# Splitting is desired here.
# shellcheck disable=SC2086
set -- $args

# Print a message:
# msg normal "This is a normal message"
# Log error and exit 3:
# msg error "Encountered an error" 3
# Splitting is impossible here.
# shellcheck disable=SC2086
msg() {
	printf "[1m=>"
	case $1 in
	normal) printf "[36m";;
	success) printf "[32m";;
	warning) printf "[33m";;
	error) printf "[31m";;
	prompt) printf "[35m";;
	esac
	printf "ppmpss[0m: %s" "$2"
	[ $1 = prompt ] || echo
	[ $1 = error ] && exit $3
}

# Exit script if response isn't yes.
# prompt "Install $pkg"
prompt() {
	msg prompt "$1? [y/n] "
	read -r RESPONSE
	case $RESPONSE in
	[Yy] | [Yy]es) :;;
	[Nn] | [Nn]o) msg error "Aborting..." 0;;
	*) msg error "Invalid response: $RESPONSE" 5;;
	esac
	unset RESPONSE
}

# usage COMMAND
# usage pkg -> Print usage for pkg command and exit 1.
usage() {
	printf "[1mUsage[0m: %s " "$0"
	case $1 in
	ppmpss) echo "COMMAND [ARGS]";;
	pkg) echo "pkg PKG";;
	em) echo "em PKG";;
	esac
	echo
	[ $1 = ppmpss ] && {
		printf "Use %s --help for help\n" "$0"
		exit 1
	}
	printf "See %s %s --help for more details\n" "$0" "$1"
	exit 1
}

# Similar to usage, but more in depth and exit 0.
# Show help for pkg command and exit 0:
# help pkg
help() {
	case $1 in
	ppmpss) cat << _EOF
[1mUsage[0m: $0 COMMAND [ARGS]

[1mCOMMAND[0m:

pkg PKG
	Fetch, build, and install PKG to empty DESTDIR.

em PKG
	$0 pkg PKG and install it to the system.
_EOF
		;;
	# TODO: Write help screens for commands.
	pkg) ;;
	em) ;;
	help) ;;
	*) msg error "Unknown command: $1" 2
	esac
	exit 0
}

# Prepare the package template and set warnings if needed.
do_prepare() {
	pkg_src=$PKGSDIR/$1
	. $pkg_src/template ||
		msg error "Failed to parse template for $1" 3
	[ $build_style = meta ] && short_desc="$pkg_src - meta package"
	[ -z "$license" ] && LICENSE_WARN=true
	[ -z "$revision" ] && [ $build_style != meta ] && REVISION_WARN=true
	[ -z "$build_style" ] && [ -z "$(command -v do_install)" ] &&
		msg error "No build_style or do_install() specified" 4
}

# Get the source, can be overriden.
[ -z "$(command -v do_fetch)" ] && {
	do_fetch() {
		[ -z "$distfiles" ] && [ -z "$giturl" ] &&
			msg error "No distfiles or giturl specified" 3
	}
}

[ -z "$(command -v do_extract)" ] && {
	do_extract() {
		case ${1##*.} in
			gzip | gz | tgz) gzip -d $1;;
			xz | lzma) lzma -d $1;;
		esac
	}
}

# Configure the source before being built, can be overriden.
# Initialize variables.
: "${configure_script:=configure}"
: "${configure_args:=--prefix=/usr}"
[ -z "$(command -v do_configure)" ] && {
	do_configure() {
		case $build_style in
		makefile) :;;
		configure) sh $configure_script $configure_args;;
		meta) :;;
		*) msg error "Unknown build_style: $build_style" 2;;
		esac
	}
}

# Build the package, can be overriden.
# Initialize variables.
: "${make_build_args:=CC=$CC CXX=$CXX}"
# Splitting is desired here.
# shellcheck disable=SC2086
[ -z "$(command -v do_build)" ] && {
	do_build() {
		case $build_style in
		makefile | configure) make $make_build_args;;
		meta) :;;
		*) msg error "Unknown build_style: $build_style" 2;;
		esac
	}
}

# Install package to empty DESTDIR, can be overriden.
# Splitting is desired here.
# shellcheck disable=SC2086
: "${make_install_args:=PREFIX=$PREFIX DESTDIR=$DESTDIR}"
[ -z "$(command -v do_install)" ] && {
	do_install() {
		case $build_style in
		makefile | configure) make $make_install_args install;;
		esac
	}
}

# Handle --help flag / empty arguments.
[ $HELP = true ] && {
	[ $# -eq 0 ] && help ppmpss
	[ $# -gt 1 ] && help help
	help $1
}
[ $# -eq 0 ] && usage ppmpss

# TODO: Add more commands
case $1 in
[Pp]kg | [Pp]ackage)
	shift
	# TODO: Code it
	[ $# -eq 0 ] && usage pkg
	for arg; do (
		[ -n "$deps" ] && $0 pkg $deps
		# Start packaging code here
		)
	done
	;;
[Ee]m | [Ee]merge)
	shift
	# TODO: Code it
	[ $# -eq 0 ] && usage em
	[ $SKIP = false ] && prompt "Emerge $*"
	for arg; do (
		$0 pkg "$arg"
		[ -n "$deps" ] && $0 em -y "$deps"
		# Start emerging code here
		)
	done
	;;
*) msg error "Unknown command: $1" 5;;
esac

exit 0
