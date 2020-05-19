# routinator-xr
Docker build script to run Routinator 3000 on IOS-XR, please see the blog at https://xrdocs.io/blogs/routinator-hosted-on-xr for much more detail.   

Launched with a container built as "routinator-xr" or alternatively can be run using the Docker hub with `philxor/routinator-xr`. Full example options listed below.    

Note IOS-XR does not require the port be exposed using "-p" when running the container, it will externally listen to any port the container application binds.  

<pre>
docker run --name routinator \
           --restart always \
           --detach \
           --cap-add SYS_ADMIN \
           -v /misc/app_host:/data \
           -v /var/run/netns/global-vrf:/var/run/netns/global-vrf \
           -e VRF=global-vrf \
           -e RSYNC_PROXY=proxy.test.ciscocom:80 \
           -e RRDP_PROXY=http://proxy.test.cisco.com:80 \
           -e NS1=171.70.168.183 \
           -e NS2=171.70.168.184 \
           -e RTR_PORT=3323 \
           -e HTTP_PORT=9556 \
           routinator-xr
</pre> 

## Docker Options  
|Options| Purpose | 
|------------|--------------------------------------------------------------------------------| 
| --name     | Sets the name of the running containe, default  | 
| --restart always | Will automatically restart a container on exit or reload of the host | 
| --detach   | Run container in the background, running in the foreground is useful for debugging |
| --cap-add  | Must be set to SYS_ADMIN to allow access to the network namespace | 
| -v         | This option mounts host volumes within the container. The namespace utilized by the container must be mounted and the RPKI data directory must be mounted  


## Environment variables 
Environment variables specified with -e are how docker passes arguments to containers. 

|Environment Variable | Default | Definition | 
|------|------|--------------------------------------------------------------------------| 
| VRF | global-vrf |  Sets the IOS-XR namespace routinator runs in. global-vrf is the global routing table |
| RSYNC_PROXY | none | If your environment requires a proxy to reach RSYNC destinations, use this variable. The rsync proxy is not prefixed by http/https |  
| RRDP_PROXY | none | RRDP uses HTTPS, so if you require a HTTPS proxy use this variable |  
| NS1 | 208.67.222.222 |  Primary nameserver | 
| NS2 | 208.67.220.220 |  Secondary nameserver |
| RTR_PORT | 3323 | RTR server port | 
| HTTP_PORT | 9556 | Routinator HTTP API port | 
