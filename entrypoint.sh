#!/bin/bash

if [[ $1 == "init" ]]; 
then 
   echo "Creating RPKI data directory at /misc/app_host/rpki"
   mkdir -p /data/rpki/tals
   mkdir -p /data/rpki/repository
   chown -R routinator:routinator /data/rpki/

   echo "Copying TAL data from container to host directory"
   sudo -u routinator cp /home/routinator/.rpki-cache/tals/* /data/rpki/tals
   
   echo "Please read the ARIN RPA at https://www.arin.net/resources/manage/rpki/rpa.pdf"  
   read -p "If you agree with the ARIN RPA type 'yes', any other input will mean non-agreement and the ARIN TAL will NOT be installed: " ARIN_RPA 
   if [ "$ARIN_RPA" = "yes" ];
   then 
      echo "User agreed to ARIN TAL, copying ARIN TAL file"  
      sudo -u routinator cp /home/routinator/.rpki-cache/tals/arin/* /data/rpki/tals
   else 
      echo "User declined ARIN TAL, will not be installed in TALS directory. Rerun init to copy, or copy manually after agreeing" 
   fi 
elif [ ! "$#" -eq 0 ];
then
  echo "Starting command $@"
  exec "$@"
else
   if [[ ! -d "/data/rpki" ]];
      then  
      echo "Please run container with 'init' to create directories and copy TAL files" 
      exit 1
   fi 
   VRF="${VRF:-global-vrf}"
   echo "Using $VRF as namespace, override default of global-vrf with -e VRF=vrf if using a different VRF for TPA"
   
   RTR_PORT="${RTR_PORT:-3323}"
   echo "Using $RTR_PORT as RTR server port, override default of 3323 with -e RTR_PORT=port"  
   
   HTTP_PORT="${HTTP_PORT:-9556}"
   echo "Using $HTTP_PORT as Routinator HTTP server port, override default of 9556 with -e HTTP_PORT=port"  

   if [[ -v RSYNC_PROXY ]];
   then
      echo "Using $RSYNC_PROXY as rsync proxy"
   else
      echo "No rsync proxy set, set using -e RSYNC_PROXY=proxy (not URI) in docker run if required"
   fi
   if [[ -v RRDP_PROXY ]];
   then
      echo "Using $RRDP_PROXY as rrdp proxy"
      RRDP_ARG="--rrdp-proxy=${RRDP_PROXY}"
   else
      echo "No RRDP proxy set, set using -e RRDP_PROXY=proxy (URI form) in docker run if required"
   fi

   NS1="${NS1:-208.67.222.222}"
   echo "Using "$NS1" as primary DNS server, override with -e NS1=nameserver to override default of 208.67.222.222"
   echo "nameserver "$NS1"" > /etc/resolv.conf
   
   NS2="${NS2:-208.67.220.220}"
   echo "Using "$NS2" as secondary DNS server, override with -e NS2=nameserver to override default of 208.67.220.220"
   echo "nameserver "$NS2"" >> /etc/resolv.conf


   echo "Starting Routinator"
   ip netns exec ${VRF} sudo -E -u routinator routinator \
                                        --base-dir /data/rpki/ \
                                        --verbose \
                                        $RRDP_ARG \
                                        server --rtr 0.0.0.0:$RTR_PORT --http 0.0.0.0:$HTTP_PORT
fi
