#!/bin/bash

if [ ! "$#" -eq 0 ];
then
  echo "Starting command $@"
  exec "$@"
else
   VRF="${VRF:-global-vrf}"
   echo "Using default $VRF as namespace, override with -e VRF=vrf if using a different VRF for TPA"

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
   echo "Using default "$NS1" as primary DNS server, override with -e NS1=nameserver to override default of 208.67.222.222"
   echo "nameserver "$NS1"" > /etc/resolv.conf
   
   NS2="${NS2:-208.67.220.220}"
   echo "Using default "$NS2" as secondary DNS server, override with -e NS2=nameserver to override default of 208.67.220.220"
   echo "nameserver "$NS2"" >> /etc/resolv.conf

   echo "Creating RPKI data directory at /misc/app_host/rpki"
   mkdir -p /data/rpki/tals
   mkdir -p /data/rpki/repository
   chown -R routinator:routinator /data/rpki/

   echo "Copying TAL data from container to host directory"
   sudo -u routinator cp /home/routinator/.rpki-cache/tals/* /data/rpki/tals

   echo "Adding nameserver in ${VRF} namespace"
#   ip netns exec ${VRF} echo "nameserver ${NS1}" > /etc/resolv.conf
#   ip netns exec ${VRF} echo "nameserver ${NS2}" >> /etc/resolv.conf

   echo "Starting Routinator"
   ip netns exec ${VRF} sudo -E -u routinator routinator \
                                        --base-dir /data/rpki/ \
                                        --verbose \
                                        $RRDP_ARG \
                                        server --rtr 0.0.0.0:3323 --http 0.0.0.0:9556
fi
