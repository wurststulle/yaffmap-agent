#!/bin/sh
. /etc/functions.sh
include /lib/network/

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


config_get_batch(){
	for s in $*
	do
		eval "config_get $s \"$1\" $s"
	done
}

wifi_default_config(){

cat <<EOF >> /etc/config/freifunk_map

config rf-iface $config
	option	'antDirection'	'0'
	option	'antGain'	'2'
	option	'antBeamH'	'360'
	option	'antBeamV'	'90'
	option	'antPol'	'V'
	option	'antTilt'	'0'
	option	'ignore'	'0'

EOF

}

wired_default_config(){

cat <<EOF >> /etc/config/freifunk_map

config wired-iface $config
	option	'bandwidth'	'100M'
	option	'duplex'	'full'
	option	'ignore'	'0'

EOF

}

interface_addresses(){
	ip_params(){		
		local config=$1
		config_get_batch "$config" ipaddr ip6addr
		[ -n "$ipaddr" ] && attr ipv4Addr $ipaddr
		[ -n "$ip6addr" ] && attr ipv6Addr $ip6Addr
	}

	local config=$1
	config_get_batch "$config" ifname type aliases
	macaddr=$( ip addr show dev $ifname | grep -e '.*:.*:.*:.*:.*:.*' | cut -d" " -f 6 )
	attr macAddr $macaddr
	ip_params $config
	[ "$type" = "bridge" ] && attr bridgeName "$ifname"

	[ -n "$aliases" ] && {
		array ipAlias
			for a in $aliases
			do
				obj
					config_get ifname "$a" ifname
					attr name $ifname
					ip_params $a
				endobj
			done
		endarr
	}
}


wifi_device_attributes(){
#	echo "entered wifi_device_attributes()"
	
	wifi_iface_attributes(){
#		echo "entered wifi_iface_attributes()"
		local config="$1"
	
		config_get device "$config" device
		if [ "$device" = "$2" ]
		then
			config_get_batch "$config" ssid bssid mode ifname
			obj
				[ -n "$ssid" ] && attr essid $ssid
				[ -n "$bssid" ] && attr bssid $bssid
				[ -n "$mode" ] && attr wlMode $mode
				config_get network "$config" network
				config_get ifname "$config" ifname
				attr name $ifname
				wlmac=$( ip addr show dev $ifname | grep -e '.*:.*:.*:.*:.*:.*' | cut -d" " -f 6 )
				attr wlMacAddr $wlmac
				interface_addresses $network
			endobj
		fi
	} 

	local config="$1"
	
	[ "$VIRGIN_MODE" = "1" ] && wifi_default_config	$config
	
	ignore=$(uci get freifunk_map.$config.ignore)
	
	if [ "$ignore" != "1" ]
	then
		config_get_batch "$config" type channel hwmode txpower macaddr antDirection antGain antBeamH antBeamV antPol antTilt macaddr
		obj
			attr name $config
			
			for s in antDirection antGain antBeamH antBeamV antPol antTilt channel txpower
			do
				eval "var_cont=\$$s"
				[ -n "$var_cont" ] && attr $s $var_cont
			done
			[ -n "$hwmode" ] && attr wirelessStandard "802.$hwmode"
			
			array wlIface
				config_foreach wifi_iface_attributes wifi-iface $config
			endarr
		endobj
	fi
}

network_interfaces(){
#  echo "entered network_interfaces()"
	network_iface(){
		local config=$1
		local isbridge=0
		
		[ "$VIRGIN_MODE" = "1" ] && wired_default_config $config

		ignore=$(uci get freifunk_map.$config.ignore)
		
		if [ "$ignore" != "1" ]
		then
			obj
				config_get ifname "$config" ifname
				attr name $ifname
				interface_addresses $config
			endobj
		fi
	}
	
	make_widev_list(){
		WIFI_DEVICES="$WIFI_DEVICES $1"
	}

	array wiredIface
		config_load network
		scan_interfaces
		config_foreach network_iface interface
	endarr

	array wlDevice
		config_load wireless
		config_foreach make_widev_list wifi-device
		for wd in $WIFI_DEVICES
		do
			wifi_device_attributes $wd
		done
	endarr
}

olsr_links(){
#	echo "entered olsr_links()"
	olsr_config=$1
	obj olsr
		attr metric $( grep LinkQualityAlgorithm $olsr_config | cut -d" " -f2 | sed 's/"//g' ) 
		ipversion=$( grep IpVersion $olsr_config | cut -d" " -f2 )
		attr ipv $ipversion 
    
		case "$ipversion" in
			"4" ) exec<<EOM
	    $( wget -T30 -q -O- http://127.0.0.1:2006/links | grep -e ^[1-9] )
EOM
					;;
			"6" ) exec<<EOM
	    $( wget -T30 -q -O- http://[::1]:2006/links | grep -e ^[1-9] )
EOM
					;;
		esac

		array link        
		while read my_ip n_ip hyst lq nlq etx 
		do
			if [ -n "$n_ip" -a "$etx" != "INFINITE" ]; then
				obj
					attr sourceAddr $my_ip
					attr destAddr $n_ip
					attr metric $lq
				endobj
			fi
		done 
		endarr 
	endobj
}

rp_links(){
  for config in /var/etc/olsrd.conf /var/etc/olsrd-ipv6.conf
  do
    [ -e $config ] && olsr_links $config
  done
  DATA="$DATA$1"
}


full_node_update(){
#	echo "entered full_node_update()"
#  if [ ! -e /tmp/ff_map_cache ]
#  then
    DATA="node="
    obj
    	config_get_batch ffmap id interval timeout
      attr id $nodeid ,
      attr updateInterval $interval ,
      attr timeout $timeout ,
#      attr longitude $( nvram get ff_adm_latlon | cut -d"," -f1 | cut -d";" -f1 ) ,
#      attr latitude $( nvram get ff_adm_latlon | cut -d"," -f2 | cut -d";" -f2 | sed 's/ //g' ) ,
      attr hostname $( uname -n )

			network_interfaces
#      echo $DATA > /tmp/ff_map_cache
#  else
#    DATA=$( cat /tmp/ff_map_cache )
#  fi
    
    obj neighbour
      rp_links
    endobj
  endobj
  rem_trailing_comma
}

URL="http://wurststulle.dyndns.org/ffmap/build/index.php"

if [ ! -e /etc/config/freifunk_map ]
then
	echo "kein config-file"
	cat <<EOF > /etc/config/freifunk_map

config 'ffmap' 'ffmap'
	option	'id' '0'
	option	'interval' '1'
	option	'timeout' '5'

EOF
	VIRGIN_MODE=1

	macAddr=$( ip addr show dev eth0 | grep -e '.*:.*:.*:.*:.*:.*' | cut -d" " -f 6 )
	returnstring=$( wget -T30 -q -q -O- "$URL?do=getID&type=wired&macAddr=$macAddr" )
	errorcode=$( echo $returnstring | cut -d"|" -f1 )
	errormessage=$( echo $returnstring | cut -d"|" -f2 )
	returndata=$( echo $returnstring | cut -d"|" -f3 )
	
	eval "$returndata"

	uci set freifunk_map.ffmap.id="$id"
	uci commit
	
fi

config_load freifunk_map
config_get nodeid ffmap id
if [ "$nodeid" = "0" -o -z "$nodeid" ] 
then
	echo "Error while getting ID. NodeID is 0 or empty."
	return 0
fi

full_node_update
#URL="$URL?do=testJson&"$DATA
URL="$URL?do=update&"$DATA

#length=${#URL}
#echo "\$URL is $length long"
#echo $URL

returnstring=$( wget -T30 -q -O- $URL )
echo $returnstring
