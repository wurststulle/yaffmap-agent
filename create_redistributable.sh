#!/bin/sh

if [ -z "$1" ]
then
	echo "you missed to give platform name"
	return 0
fi

cd files
tar --exclude=".svn" --exclude="*~"  -cf ../$1_redist.tar etc/init.d/yaffmap lib/yaffmap/common* lib/yaffmap/$1*