#!/bin/bash

set -e

if [ ! -f /etc/nginx/ssl/server.crt ]; then
	openssl req -x509 -nodes -days 365 \
		-newkey rsa:2048 \
		-keyout /etc/nginx/ssl/server.key \
		-out /etc/nginx/ssl/server.crt \
		-subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=Inception/CN=login.42.fr"
fi

exec "$@"
