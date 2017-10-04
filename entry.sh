#!/bin/bash

Eth1IP=$(ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d ' ' -f 1)
Eth0IP=$(ifconfig eth0 | grep "inet addr:" | cut -d: -f2 | cut -d ' ' -f 1)
DOMAIN="nginx"
CONFIG="/default.conf"

country="US"
state="CA"
locality="San Jose"
commonname=$Eth0IP
org="Cisco Systems Ltd."
unit="DCNM"
email="dcnm-afw@cisco.com"

fail_if_error() {
  [ $1 != 0 ] && {
    unset PASSPHRASE
    exit 10
  }
}

# Generate a passphrase
export PASSPHRASE="justintime"

openssl genrsa -des3 -out $DOMAIN.key -passout env:PASSPHRASE 2048
fail_if_error $?

# Generate the CSR
openssl req \
    -new \
    -batch \
    -subj "/C=$country/ST=$state/L=$locality/O=$org/OU=$unit/CN=$commonname/emailAddress=$email" \
    -key $DOMAIN.key \
    -out $DOMAIN.csr \
    -passin env:PASSPHRASE
fail_if_error $?

# Strip the password so we don't have to type it every time we restart Apache
openssl rsa -in $DOMAIN.key -out $DOMAIN.key -passin env:PASSPHRASE
fail_if_error $?

# Generate the cert (good for 10 years)
openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
fail_if_error $?

# Copy .crt and .key into nginx conf.d folder
cp $DOMAIN.key /etc/nginx/conf.d/
cp $DOMAIN.crt /etc/nginx/conf.d/

# Delete .crt and .key into nginx conf.d folder
rm -rf $DOMAIN.key $DOMAIN.crt $DOMAIN.csr

sed -i "s/DCNMIP/$DCNMVIP/g" $CONFIG
cp $CONFIG /etc/nginx/conf.d/default.conf
cat /etc/nginx/conf.d/default.conf

nginx -g "daemon off;"
