#!/bin/sh

ANNOUNCE_URL="http://wurststulle.dyndns.org/yaffmap/index.php"
VERSIONMAPPING=0

usage(){
	echo "usage: $0 -t tree -v version -r release [-m]"
	echo "       tree      stable|devel"
	echo "       version   e.g. uci or fff"
	echo "       release   e.g. 0.1-1"
	echo "       -m		automatically create backend compatibility mapping on server"
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
	[ "$VERSIONMAPPING" = "1" ] && vmappingstring="&mapping=1" || vmappingstring=""
	returnstring=$( curl --upload-file ../yaffmap_${RELEASE}_${VERSION}_${TREE}.tar.gz  "$ANNOUNCE_URL?do=newAgentReleaseWithFile&tree=$TREE&version=$VERSION&release=$RELEASE$vmappingstring" )
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
		echo "Transmit String: $ANNOUNCE_URL?do=newAgentReleaseWithFile&tree=$TREE&version=$VERSION&release=$RELEASE"
		echo
		check_error 1 "upload to webserver"
	fi
	
	return $error
}


while [ -n "$1" ]
do
	case $1 in
		"-r"	)	RELEASE=$2 
						shift ;;
		"-v"	)	VERSION=$2 
						shift ;;
		"-t"	)	TREE=$2 
						shift ;;
		"-m"	)	VERSIONMAPPING=1 
						;;
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
echo "$TREE:$RELEASE" > lib/yaffmap/release.txt
tar --exclude=".svn" --exclude="*~"  -czf ../yaffmap_${RELEASE}_${VERSION}_${TREE}.tar.gz etc/init.d/yaffmap lib/yaffmap/common* lib/yaffmap/$VERSION* lib/yaffmap/release.txt
check_error $? "tarball creation"

#upload
echo "Uploading to webserver"
announce
check_error $? "upload to webserver"