#!/bin/sh

# vim: ts=4 sw=4 noet cc=80

# shellcheck disable=SC2154

trap interrupt 2

# message and format
msgf() {
	printf "[1m=>"
	case $1 in
	normal) printf "[36m" ;;
	warning) printf "[33m" ;;
	pass) printf "[32m" ;;
	prompt) printf "[35m" ;;
	error) printf "[31m"; shift ;;
	esac

	shift
	# shellcheck disable=SC2059
	# shellcheck disable=SC2145
	printf "ppmpss[0m: $@"
}

# Send msg and format
logf() {
	msgf normal "$@"
}

# Send pass msg and format
passf() {
	msgf pass "$@"
}

# Send warning and format
warnf() {
	msgf warning "$@"
}

# Error and format message
errorf() {
	CODE=$1
	msgf error "$@"
	exit "$CODE"
}

# Prompt and format message
promptf() {
	msgf prompt "$@"
	printf " [y/N]: "
	read -r RESPONSE
	case $RESPONSE in
	[Yy] | [Yy]es) :;;
	[Nn] | [Nn]o | "") errorf 0 "Aborting...\n" ;;
	*) errorf 1 "Unknown response: %s\n" "$RESPONSE" ;;
	esac
	unset RESPONSE
}

# Handle command interrupt
interrupt() {
	echo
	errorf 2 "Command interrupted\n"
}

# Give basic usage and exit
usage() {
	printf "[1musage[0m: "
	case $1 in
	help) printf "%s help [command]\n" "$0" ;;
	esac
	exit 1
}

# Splitting is desired here
# shellcheck disable=SC2086
package_configure() {
	[ "$(command -v do_configure)" ] && {
		do_configure
		return
	}
	case $build_style in
		configure)
			: "${configure_script:=configure}"
			: "${configure_args:=--prefix=$PREFIX}"

			sh $configure_script $configure_args
			;;
		makefile | meson) :;;
	esac
}

# Splitting is desired here
# shellcheck disable=SC2086
package_build() {
	case $build_style in
		configure | makefile)
			: "${CC:=gcc}"
			: "${CXX:=g++}"

			: "${make_cmd:=make}"
			: "${make_build_args:=CC=$CC}"

			$make_cmd $make_build_args
			;;
		meson)
			meson build
			ninja -C build
			;;
	esac
}

# Splitting is desired here
# shellcheck disable=SC2086
package_install() {
	case $build_style in
		configure | makefile)
			: "${make_cmd:=make}"
			: "${make_install_args:=PREFIX=$PREFIX DESTDIR=$DESTDIR}"

			$make_cmd $make_install_args install
	esac
}

for flag in SKIP HELP; do
	eval $flag=false
done

# Parse options and store non-option args
args=
while [ $# -gt 0 ]; do
	case $1 in
	--[Pp]kgs_[Dd]ir=* | --[Pp]kgs_[Dd]irectory=*) PKGSDIR=${1#*=} ;;
	--[Pp]kgs_[Dd]ir | --[Pp]kgs_[Dd]irectory) PKGSDIR=$2; shift ;;
	--[Rr]epo=* | --[Rr]epository=*) REPO=${1#*=} ;;
	--[Rr]epo | --[Rr]epository) REPO=$2; shift ;;
	-[Hh] | --[Hh]elp) HELP=true ;;
	-[Yy] | --[Yy]es) SKIP=true ;;
	--) break ;;
	-*) error 1 "Unknown option: %s\n" "$1" ;;
	*) args="$args $1" ;;
	esac
	shift
done
# Splitting is desired here
# shellcheck disable=SC2086
set -- $args

# Handle args
[ $HELP = true ] && {
	[ $# -gt 0 ] && usage help
	[ $# = 1 ] && help "$1"
	[ -z "$1" ] && help ppmpss
}

# Process commands
case $1 in
	[Pp]kg | [Pp]ackage)
		shift
		;;
	*) errorf 1 "Unknown command: %s\n" "$1" ;;
esac

sleep 5

exit 0
