#!/bin/sh

ANNOUNCE_URL="http://wurststulle.dyndns.org/yaffmap/index.php"

usage(){
	echo "usage: $0 -t tree -v version -r release"
	echo "       tree      stable|devel"
	echo "       version   e.g. uci or fff"
	echo "       release   e.g. 0.1-1"
}

check_error(){
	local error=$1
  ERROR_REASON=$2
	if [ ! $error -eq 0 ]
	then
		echo "Error! It happened because of/while $ERROR_REASON"
		exit 0
	fi
}

announce(){
	local txurl="$1"

	returnstring="$( wget -T30 -q -O- $txurl )"
	check_error $? "announcement to webserver"

	errorcode=$( echo $returnstring | cut -d"|" -f1 )
	errormessage=$( echo $returnstring | cut -d"|" -f2 )
	SERVER_RESPONSE=$( echo $returnstring | cut -d"|" -f3 )

	if [ ! "$errorcode" = "0" ] 
	then
		echo "Map Server returned error"
		echo 
		echo "Error Code: $errorcode"
		echo 
		echo "Error Text: $errormessage"
		echo 
		echo "Transmit String: $txurl"
		echo
		check_error 1 "response from announcement server"
	fi
}


while [ -n "$1" ]
do
	case $1 in
		"-r"	) release=$2 
						shift ;;
		"-v"	)	version=$2 
						shift ;;
		"-t"	)	tree=$2 
						shift ;;
		"-h"	) head=1 ;;
	esac
	shift
done	


for s in release version tree
do
	eval "tmp=\$$s"
	if [ -z "$tmp" ]
	then
		echo "You forgot to specify the $s."
		usage
		exit 0
	fi
done


#packaging
echo "Creating tarball."
cd files
echo "$release" > lib/yaffmap/release.txt
tar --exclude=".svn" --exclude="*~"  -czf ../yaffmap_${release}_${version}_${tree}.tar.gz etc/init.d/yaffmap lib/yaffmap/common* lib/yaffmap/$version* lib/yaffmap/release.txt
check_error $? "tarball creation"

#announce
echo "Announcing new release to webserver"
txurl="$ANNOUNCE_URL?do=newAgentRelease&release=$release&tree=$tree&version=$version"
announce "$txurl"

#upload
echo "Uploading to webserver"
scp -P 6667 ../yaffmap_${release}_${version}_${tree}.tar.gz wurst@wurststulle.dyndns.org:/mnt/lager/www/ffmap/build/download/
check_error $? "upload to webserver"

#announce as head
if [ "$head" -eq 1 ] 
then 
	echo "Announcing this release as head"
	txurl="$txurl&isHead=true"
	announce "$txurl"
fi
