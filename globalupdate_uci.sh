#!/bin/sh
. /etc/functions.sh

TEMP_DIR="."

#######
# JSON helper
# These functions are filling up the variable DATA if not called with the arguments -v <Variable name>.
app(){
  eval "$1=\"\$$1$2\""
}

rem_trailing_comma(){
	DATA=$( echo $DATA | sed s/.$// )
}

json_helper(){
	do="$1"
	shift
	
  if [ "$1" = "-v" ]
  then
  	var=$2
  	shift;shift
  else
    var="DATA"
  fi

		case $do in
      "obj")		[ -n "$1" ] && app $var "\\\"$1\\\":"
								app $var "{"
      					;;
			"endobj")	rem_trailing_comma
								app $var "},"
								;;
			"array")	
								[ -n "$1" ] && app $var "\\\"$1\\\":"
								app $var "["
								;;
			"endarr")	rem_trailing_comma
								app $var "],"
      					;;
      "attr")		
      					app $var "\\\"$1\\\":\\\"$2\\\","
      					;;
    esac
}

for s in obj endobj array endarr attr
do
	eval "alias $s=\"json_helper $s\""
done

#
#######



get_dnssuffix(){
	config_get suffix "$1" suffix
}

config_load olsrd
config_foreach get_dnssuffix LoadPlugin

cp /var/etc/hosts.olsr $TEMP_DIR
cp /var/run/latlon.js $TEMP_DIR

cat <<EOF > $TEMP_DIR/latlon_crawler.awk
#!/usr/bin/awk -f
BEGIN{
EOF

chmod 755 latlon_crawler.awk

awk '
{
if ($2!~/^mid[1-9]\./)
	if ($1~/^[1-9]/) 
		if ($1!~/127\.0\.0\./) {
			print "	hosts_names[\""$2","$1"\"]" 
		}
}
' $TEMP_DIR/hosts.olsr >> $TEMP_DIR/latlon_crawler.awk



cat <<EOM >> $TEMP_DIR/latlon_crawler.awk
	print "array node;"
}
{
	gsub(");","")
	gsub(","," ")
	gsub("'","")

	if ( \$1~/^Mid/ ) {
		gsub("Mid(","")
		mid[\$1]=mid[\$1]"obj;attr ipv4Addr "\$2";endobj;"
	}
	if  (\$1~/^Node/ ) {
		gsub("Node(","")
		print "obj;attr name "\$6";attr latitude "\$2";attr longitude "\$3";array iface;"
		print "obj;attr ipv4addr "\$1";endobj;"mid[\$1]"endarr;endobj;"
		delete mid[\$1]
		hostplussuffix=\$6"$suffix"
		for ( s in hosts_names ) {
			split( s, separate, "," )
			if ( separate[1] == hostplussuffix )
				delete hosts_names[s]
		}
}
}
END{
	for ( s in hosts_names ) {
		split( s, separate, "," )
		print "obj;attr name "separate[1]";array iface;obj;attr ipv4addr "separate[2]";endobj;"mid[separate[2]]"endarr"
		delete mid[separate[2]]
	}
	for ( m in mid ){
		print "obj;array iface;attr ipv4addr "m";endobj;"mid[m]"endarr;endobj;"
		}
	print "endarr"
}
EOM

eval "$( $TEMP_DIR/latlon_crawler.awk $TEMP_DIR/latlon.js )"
echo $DATA
rm $TEMP_DIR/latlon_crawler.awk $TEMP_DIR/latlon.js $TEMP_DIR/hosts.olsr