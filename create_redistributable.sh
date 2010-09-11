#!/bin/sh

#if [ -z "$1" ]
#then
#	echo "you missed to give platform name"
#fi

cd files
tar --exclude=".svn" --exclude="*~"  -cf ../luci_redist.tar *