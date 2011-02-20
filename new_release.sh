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
	returnstring=$( curl --upload-file ../yaffmap_${RELEASE}_${VERSION}_${TREE}.tar.gz  "$ANNOUNCE_URL?do=newAgentReleaseWithFile&tree=$TREE&version=$VERSION&release=$RELEASE" )
	check_error $? "upload and accouncement to webserver"

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
		check_error 1 "upload to webserver"
	fi
	
	return $error
}


while [ -n "$1" ]
do
	case $1 in
		"-r"	) RELEASE=$2 
						shift ;;
		"-v"	)	VERSION=$2 
						shift ;;
		"-t"	)	TREE=$2 
						shift ;;
		"-h"	) HEAD=1 ;;
	esac
	shift
done	


for s in RELEASE VERSION TREE
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
echo "$RELEASE" > lib/yaffmap/release.txt
tar --exclude=".svn" --exclude="*~"  -czf ../yaffmap_${RELEASE}_${VERSION}_${TREE}.tar.gz etc/init.d/yaffmap lib/yaffmap/common* lib/yaffmap/$VERSION* lib/yaffmap/release.txt
check_error $? "tarball creation"

#upload
echo "Uploading to webserver"
announce
check_error $? "upload to webserver"