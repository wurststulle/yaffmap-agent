#!/bin/sh
. /etc/functions.sh

TEMP_DIR="."

get_dnssuffix(){
	config_get suffix "$1" suffix
}

config_load olsrd
config_foreach get_dnssuffix LoadPlugin

echo $suffix

cp /var/etc/hosts.olsr $TEMP_DIR
cp /var/run/latlon.js $TEMP_DIR

cat <<EOF > $TEMP_DIR/latlon_crawler.awk
#!/usr/bin/awk -f
EOF

chmod 755 latlon_crawler.awk

awk '
BEGIN{
	print "BEGIN{"
}
{
if ($2!~/^mid[1-9]\./)
	if ($1~/^[1-9]/) 
		if ($1!~/127\.0\.0\./) {
			print "hosts_names[\""$2","$1"\"]" 
		}
}
END{
	print "}"
}' $TEMP_DIR/hosts.olsr >> $TEMP_DIR/latlon_crawler.awk



cat <<EOM >> $TEMP_DIR/latlon_crawler.awk
{
gsub(");","")
gsub(","," ")
gsub("'","")

if (\$1~mainip) {

	if ( \$1~/^Mid/ ) {
		gsub("Mid(","")
		mid[\$1]=mid[\$1]"obj;attr ipv4Addr "\$2";endobj;"
	}
	if  (\$1~/^Node/ ) {
		gsub("Node(","")
		print "obj node;attr name "\$6";attr latitude "\$2";attr longitude "\$3";array iface;"
		print "obj;attr ipv4addr "\$1";endobj;"mid[\$1]"endarr;endobj;"
		hostplussuffix=\$6"$suffix"
		for ( s in hosts_names ) {
			split( s, separate, "," )
			if ( separate[1] == hostplussuffix )
				delete hosts_names[s]
		}
	}
}
}
END{
for ( s in hosts_names ) {
	split( s, separate, "," )
	print "obj node;attr name "separate[1]";array iface;obj;attr ipv4addr "separate[2]":endobj;endarr"
}
}
EOM

$TEMP_DIR/latlon_crawler.awk $TEMP_DIR/latlon.js
rm $TEMP_DIR/latlon_crawler.awk $TEMP_DIR/latlon.js $TEMP_DIR/hosts.olsr