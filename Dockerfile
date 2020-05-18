# Build routinator binary for Linux glibc

FROM ubuntu:18.04 as build

# Proxy environment variables if needed for git  
#ENV http_proxy=http://proxy.esl.cisco.com:80
#ENV https_proxy=http://proxy.esl.cisco.com:80

# Add Tini
ENV TINI_VERSION v0.15.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  git \
  cargo \
  libssl-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/routinator

RUN git clone --depth 1 https://github.com/NLnetLabs/routinator .

RUN cargo build \
    --release \
    --locked

# Create actual routinator container with runtime arguments
FROM ubuntu:18.04
MAINTAINER bedard.phil@gmail.com

# Copy routinator binary from build image 
COPY --from=build /tmp/routinator/target/release/routinator /usr/local/bin

# Install Tini to capture ^C if running in foreground since routinator does not. Can also runing --init on run 
COPY --from=build /tini /sbin/tini
RUN chmod +x /sbin/tini

ARG RUN_USER=routinator
ARG RUN_USER_UID=1012
ARG RUN_USER_GID=1012

RUN apt-get update && apt-get install -y \
  rsync \
  iproute2 \
  iputils-ping \
  sudo \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -u $RUN_USER_GID -U $RUN_USER && \ 
    mkdir -p /home/${RUN_USER}/.rpki-cache/repository /home/${RUN_USER}/.rpki-cache/tals && \
    chown -R ${RUN_USER_UID}:${RUN_USER_GID} /usr/local/bin/routinator /home/${RUN_USER}/.rpki-cache

# Copy TAL files from source to user directory
# Requires acceptance of ARIN TAL at https://www.arin.net/resources/rpki/tal.html

COPY --from=build /tmp/routinator/tals/*.tal /home/${RUN_USER}/.rpki-cache/tals/

# Copy entrypoint.sh to root of image for execuation 
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default ports to expose. Not 100% necessary in IOS-XR since it will globally listen to ports within the container.  

EXPOSE 3323/tcp
EXPOSE 9556/tcp

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]

