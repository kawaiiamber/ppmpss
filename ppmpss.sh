#!/bin/sh

# vim: ts=4 sw=4 noet cc=80

# shellcheck disable=SC2154

BASEDIR="/usr/local/share/ppmpss"
PKGSDIR="${BASEDIR}/packages"
PKGDB="/var/db/ppmpss"

trap interrupt 2

# message and format
ppmpss_msg() {
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
msgf() {
	ppmpss_msg normal "$@"
	echo
}

# Send pass msg and format
passf() {
	ppmpss_msg pass "$@"
	echo
}

# Send warning and format
warnf() {
	ppmpss_msg warning "$@"
	echo
}

# Error and format message
errorf() {
	CODE="$1"
	ppmpss_msg error "$@"
	echo
	exit "$CODE"
}

# Prompt and format message
promptf() {
	ppmpss_msg prompt "$@"
	printf " [y/N]: "
	read -r RESPONSE
	case $RESPONSE in
	[Yy] | [Yy]es) :;;
	[Nn] | [Nn]o | "") errorf 1 "Aborting...\n" ;;
	*) errorf 2 "Unknown response: %s\n" "$RESPONSE" ;;
	esac
	unset RESPONSE
}

# Handle command interrupt
interrupt() {
	echo
	errorf 1 "Command interrupted\n" & kill 0
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
		makefile)
			: "${configure_script:=configure}"
			: "${configure_prefix_args:=--prefix=$PREFIX}"
			: "${configure_args:=}"

			[ -f "$configure_script" ] && sh $configure_script\
				$configure_prefix_args $configure_args
			;;
		meson) :;;
	esac
}

# Splitting is desired here
# shellcheck disable=SC2086
package_build() {
	case $build_style in
		makefile)
			: "${CC:=cc}"
			: "${CXX:=c++}"

			: "${make_build_args:=CC=$CC CXX=$CXX}"
			: "${make_build_target:=}"

			make $make_build_args $make_build_target
			;;
		meson)
			meson -Dprefix=/usr build
			ninja -C build
			;;
	esac
}

# Splitting is desired here
# shellcheck disable=SC2086
package_install() {
	case $build_style in
		makefile)
			: "${make_install_args:=PREFIX=/usr DESTDIR=$DESTDIR}"
			: "${make_install_target:=install}"

			make $make_install_args $make_install_target
			;;
		meson)
			ninja -C build install
			;;
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

# Handle help
[ $HELP = true ] && {
	[ $# -gt 0 ] && usage help
	[ $# = 1 ] && help "$1"
	[ -z "$1" ] && help ppmpss
}

# Process commands
case $1 in
	[Ii]nit | [Ii]nitialize)
		shift
		[ "$(id -u)" -eq 0 ] && {
			msgf "Initializing with default repo..."
			mkdir -p /usr/share/ppmpss/repos
			git -C /usr/share/ppmpss/repos clone\
				"https://github.com/kawaiiamber/ppmpss-default-repo.git"
		} || {
			mkdir -p repos
			msgf "Initializing default repo locally..."
			git -C repos clone\
				"https://github.com/kawaiiamber/ppmpss-default-repo.git"
		}
		;;
	[Pp]kg | [Pp]ackage)
		shift
		for arg; do (
			msgf "Packaging %s..." "$arg"
			for pkg_dep in $makedeps; do
				$0 pkg "$pkg_dep"
			done
		) done
		;;
	[Ee]m | [Ee]merge)
		shift
		for arg; do (
			msgf "Emerging %s..." "$arg"
			for pkg_dep in $rundeps; do
				$0 em -y "$pkg_dep"
			done
		) done
		;;
	*) errorf 1 "Unknown command: %s" "$1" ;;
esac

exit 0
