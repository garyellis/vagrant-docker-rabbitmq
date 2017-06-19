#!/bin/bash

mkdir -p /etc/registry/{auth,certs}

docker run --entrypoint htpasswd registry:2 -Bbn user Welcome1  > /etc/registry/auth/htpasswd

openssl req \
       -newkey rsa:2048 -nodes -keyout /etc/registry/certs/$HOSTNAME.key \
       -x509 -sha256 -days 365 -out /etc/registry/certs/$HOSTNAME.crt \
       -subj "/C=US/ST=Arizona/L=Phoenix/O=devel/CN=$HOSTNAME"


mkdir -p /etc/docker/certs.d/$HOSTNAME:5000

docker run -d -p 5000:5000 --restart=always --name registry \
  -v /etc/registry:/etc/registry \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/etc/registry/auth/htpasswd \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/etc/registry/certs/$HOSTNAME.crt \
  -e REGISTRY_HTTP_TLS_KEY=/etc/registry/certs/$HOSTNAME.key \
  registry:2


mkdir -p /etc/docker/certs.d/$HOSTNAME:5000
openssl s_client -connect $HOSTNAME:5000 2>/dev/null <<<""|sed -n '/-----BEGIN/,/-----END/p' > /etc/docker/certs.d/$HOSTNAME:5000/ca.crt
