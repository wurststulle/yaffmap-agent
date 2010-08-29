#!/bin/sh
. /etc/functions.sh
##########
#  JSON helper
append(){
	eval "$1=\"\$$1$2\""
}

obj(){
	[ -n "$1" ] && DATA="$DATA\"$1\":"
	append DATA "\"$1\""
#	DATA="$DATA{"
#	echo "new object"
}

endobj(){
#	DATA="$DATA}$1"
#	echo "closed object"
}

array(){
	[ -n "$1" ] && DATA="$DATA\"$1\":"
#	DATA="$DATA["
#	echo "new array $1"
}

endarr(){
#	DATA="$DATA]$1"
#	echo "closed array"
}

attr(){
#	DATA="$DATA\"$1\":\"$2\"$3"
#	echo "Attribute added: \"$1\":\"$2\"$3 "
}
#
###########

int_addresses(){
  local ifname=$1
  ipv4ad=$( ip addr show dev $ifname | grep "inet " | cut -d" " -f6 | cut -d"/" -f1 )
  [ -n "$ipv4ad" ] && attr ipv4Addr "$ipv4ad" ,
  ipv6ad=$( ip addr show dev $ifname | grep inet6 | cut -d" " -f6 | cut -d"/" -f1 )
  [ -n "$ipv6ad" ] && attr ipv6Addr "$ipv6ad" ,
  attr macAddr $( ip addr show dev $ifname | grep ether | cut -d" " -f6 )
  DATA="${DATA}$2"
}

wifi_iface_attributes(){
  
  
}

wifi_device_attributes(){
  config="$1"
  local channel wirelessStandard availFrequency
  config_get channel "$config" channel
  config_get hwmode "$config" hwmode
  
  config_foreach wifi_iface_attributes wifi-iface
  
}

wifi_interfaces(){
  config_load wireless
  config_foreach wifi_device_attributes wifi-device

  local ifname
#gather information for broadcom wifi device
  if [ -e /proc/net/wl0 ]
  then
    obj
      if [ "$(nvram get wl0_mode)" = "ap" ]; then
          wlmode=ap
      elif [ "$(nvram get wl0_infra)" = "1" ]; then
          wlmode=sta
      else
          wlmode=adhoc
      fi
      attr wlMode $wlmode ,
      attr channel $( nvram get wl0_channel ) ,
      attr bssid $( wl status | grep BSSID | cut -d" " -f2 | cut -f1 ) ,
      attr essid $( wl status | grep 'SSID: "' | cut -d" " -f2 | sed 's/"/ /g' ) ,
      ifname=$( nvram get wl0_ifname )
      attr name $ifname ,
      int_addresses $ifname ,
      obj ifaceType
        attr isWireless 1 ,
        attr wirelessStandard 802.1$( nvram get wl0_phytype ) ,
        attr availFrequency 2.4G
      endobj
    endobj 
  fi
  DATA="${DATA}$1"
}

ethernet_interfaces(){
  for s in wan lan
  do
    ifname=$( nvram get ${s}_ifname )
    if [ -n "$(ip addr show dev $ifname | grep UP)" ]
    then
      obj
        attr bandwidth 100M ,
        attr duplex full ,
        attr name $ifname ,
        int_addresses $ifname ,
        obj ifaceType
          attr isWireless 0
        endobj
      endobj $( [ "$s" = "lan" ] || echo "," ) #do not append comma if at the and of interface list
    fi
  done
  DATA="${DATA}$1" #but append one if requested
}

olsr_links(){
  olsr_config=$1
  obj olsr
    attr metric $( grep LinkQualityAlgorithm $olsr_config | cut -f2 | sed 's/"//g' ) ,
    ipversion=$( grep IpVersion $olsr_config | cut -f3 )
    attr ipv $ipversion ,

    case "$ipversion" in
      "4" ) exec<<EOM
	    $( wget -O- http://127.0.0.1:2006/links | grep -e ^[1-9] )
EOM
            ;;
      "6" ) exec<<EOM
	    $( wget -O- http://[::1]:2006/links | grep -e ^[1-9] )
EOM
            ;;
    esac

    firstrun=1
    array link        
    while read my_ip n_ip hyst lq nlq etx 
    do
       if [ "$firstrun" = "1" ]
       then
          firstrun=0	
       else
          DATA="$DATA,"
       fi
       if [ -n "$n_ip" -a "$etx" != "INFINITE" ]; then
	 obj
	   attr sourceAddr $my_ip ,
	   attr destAddr $n_ip ,
	   attr metric $lq
	 endobj
       fi
    done 
    endarr 
  endobj
  DATA="$DATA$2"
}

rp_links(){
  for config in /var/etc/olsrd.conf /var/etc/olsrd-ipv6.conf
  do
    [ -e $config ] && olsr_links $config
  done
  DATA="$DATA$1"
}


full_node_update(){
#  if [ ! -e /tmp/ff_map_cache ]
#  then
    DATA="node="
    obj
      attr id $( nvram get ffmap_id ) ,
      attr updateInterval $( nvram get ffmap_interval ) ,
      attr timeout $( nvram get ffmap_timeout ) ,
      attr longitude $( nvram get ff_adm_latlon | cut -d"," -f1 | cut -d";" -f1 ) ,
      attr latitude $( nvram get ff_adm_latlon | cut -d"," -f2 | cut -d";" -f2 | sed 's/ //g' ) ,
      attr hostname $( uname -n )

      array interface
        wifi_interfaces ,
        ethernet_interfaces
      endarr ,
#      echo $DATA > /tmp/ff_map_cache
#  else
#    DATA=$( cat /tmp/ff_map_cache )
#  fi
    
    obj neighbour
      rp_links
    endobj
  endobj
}

URL="http://wurststulle.dyndns.org/ffmap/build/index.php"

if [ -z "$( nvram get ffmap_id )" ]
then
  macAddr=$( ip addr show dev $( nvram get wl0_ifname ) | grep ether | cut -d" " -f6 )
  returnstring=$( wget -q -O- "$URL?do=getID&macAddr=$macAddr" )
  errorcode=$( echo $returnstring | cut -d"|" -f1 )
  errormessage=$( echo $returnstring | cut -d"|" -f2 )
  returndata=$( echo $returnstring | cut -d"|" -f3 )
  eval "$returndata"
  nvram set ffmap_id=$id
  nvram set ffmap_interval=1
  nvram set ffmap_timeout=5
fi

full_node_update
#URL="$URL?do=testJson&"$DATA
URL="$URL?do=update&"$DATA

#length=${#URL}
#echo "\$URL is $length long"
#echo $URL

wget -q -O- $URL
