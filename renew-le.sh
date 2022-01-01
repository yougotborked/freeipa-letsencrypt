#!/usr/bin/bash
set -o nounset -o errexit

WORKDIR=$(dirname "$(realpath $0)")
EMAIL=${EMAIL:-""}
DOMAIN=coruscant.lab.abork.co

if [[ -z "$EMAIL" ]]; then
	echo "EMAIL is not set"
	exit 1
fi

# This is needed for enabling the certificates
# TODO : Store safely
DIRPASSWD=${DIRPASSWD:-""}

if [[ -z "$DIRPASSWD" ]]; then
	echo "DIRPASSWD is not set"
	exit 1
fi

### cron
# check that the cert will last at least 2 days from now to prevent too frequent renewal
# comment out this line for the first run
if [ "${1:-renew}" != "--first-time" ]
then
        echo "Checking when certificate was renewed"
        start_timestamp=`date +%s --date="$(openssl x509 -startdate -noout -in /var/lib/ipa/certs/httpd.crt | cut -d= -f2)"`
        now_timestamp=`date +%s`
        diff=$(((now_timestamp-start_timestamp) / 86400))
        if [ "$diff" -lt "2" ]; then
                echo "No renewal needed"
                exit 0
        fi
fi

cd "$WORKDIR"
# cert renewal is needed if we reached this line
echo "Renewal needed"

OPENSSL_PASSWD_FILE="/var/lib/ipa/passwds/$HOSTNAME-443-RSA"
[ -f "$OPENSSL_PASSWD_FILE" ] && OPENSSL_EXTRA_ARGS="-passin file:$OPENSSL_PASSWD_FILE" || OPENSSL_EXTRA_ARGS=""
OPENSSL_PASSPHRASE=$( /usr/libexec/ipa/ipa-httpd-pwdreader $HOSTNAME:443 RSA)
[[ -n "$OPENSSL_PASSPHRASE" ]] && OPENSSL_EXTRA_ARGS="$OPENSSL_EXTRA_ARGS -passin pass:$OPENSSL_PASSPHRASE"
# generate CSR
if [ ! -f "$WORKDIR/req.csr" ]
then
	openssl req -new -config "$WORKDIR/ipa-httpd.cnf" -keyout "$WORKDIR/req.key" -out "$WORKDIR/req.csr"
fi

echo "$DIRPASSWD" | kinit admin

# httpd process prevents letsencrypt from working, stop it
#service httpd stop

# get a new cert
letsencrypt --debug -v certonly --csr "$WORKDIR/req.csr" --email "$EMAIL" --agree-tos --no-eff-email --manual --preferred-challenges dns -d "$DOMAIN" --cert-path "$WORKDIR/cert.pem" --chain-path "$WORKDIR/chain.pem" --fullchain-path "$WORKDIR/fullchain.pem" --manual-public-ip-logging-ok --manual-auth-hook "$WORKDIR/certbot-dns-ipa.py" --manual-cleanup-hook "$WORKDIR/certbot-dns-ipa.py" || EXIT_CODE=$?

#uncomment this to do it fully manually
#letsencrypt --debug -v certonly --csr "$WORKDIR/req.csr" --email "$EMAIL" --agree-tos --no-eff-email --manual --preferred-challenges dns -d "$DOMAIN" --cert-path "$WORKDIR/cert.pem" --chain-path "$WORKDIR/chain.pem" --fullchain-path "$WORKDIR/fullchain.pem" --manual-public-ip-logging-ok || EXIT_CODE=$?


# replace the cert

#backup temporarally
cp "$WORKDIR/req.key" /tmp/req.key 
cp "$WORKDIR/cert.pem" /tmp/cert.pem

#uncomment this line to fix any expiration isues
#date -s "10 DEC 2021"

#service httpd start

yes $DIRPASSWD "" | ipa-server-certinstall -w -d "$WORKDIR/req.key" "$WORKDIR/cert.pem"
ipactl restart

mv "$WORKDIR/cert.pem"  "$WORKDIR/cert.pem.save"
mv "$WORKDIR/chain.pem"  "$WORKDIR/chain.pem.save"
mv "$WORKDIR/fullchain.pem"  "$WORKDIR/fullchain.pem.save"
