#!/bin/sh

# $Id: create_distrib.sh,v 1.15 2013/04/01 10:26:29 rousseau Exp $

# create a new directory named after the current directory name
# the directory name should be in the form foo-bar.x.y.z
# the use of "_" is not recommanded since it is a problem for Debian

# exit in case of error
set -e
set -x

dir=$(basename "$(pwd)")

echo "Using $dir as directory name"

SED=gsed
rv=$(echo "$dir" | $SED -e 's/.*-[0-9]\+\.[0-9]\+\.[0-9]\+/ok/')
if [ "$rv" != "ok" ]
then
	echo "ERROR: The directory name should be in the form foo-bar-x.y.z"
	exit
fi

if [ -e "$dir" ]
then
	echo "ERROR: $dir already exists"
	echo "remove it and restart"
	exit
fi

# generate Changelog
#/usr/share/cvs/contrib/rcs2log > Changelog

present_files=$(mktemp)
manifest_files=$(mktemp)
diff_result=$(mktemp)

# clean dir
if [ -e Makefile ]
then
	make distclean
fi

# find files present
# remove ^debian and ^create_distrib.sh
find . -type f | grep -v CVS | cut -c 3- | grep -v ^create_distrib.sh | sort > "$present_files"
cat MANIFEST | sort > "$manifest_files"

# diff the two lists
diff "$present_files" "$manifest_files" | grep '<' | cut -c 2- > "$diff_result"

if [ -s "$diff_result" ]
then
	echo "ARNING! some files will not be included in the archive."
	echo "Add them in MANIFEST"
	cat "$diff_result"
	echo
fi

# remove temporary files
rm "$present_files" "$manifest_files" "$diff_result"

# create the temporary directory
mkdir "$dir"

for i in $(cat MANIFEST)
do
	if [ $(echo $i | grep /) ]
	then
		idir=$dir/${i%/*}
		if [ ! -d "$idir" ]
		then
			echo "mkdir -p $idir"
			mkdir -p "$idir"
		fi
	fi
	echo "cp $i $dir/$i"
	cp -a "$i" "$dir/$i"
done

tar cjvf ../"$dir".tar.bz2 "$dir"
rm -r "$dir"

