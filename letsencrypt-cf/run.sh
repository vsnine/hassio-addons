#!/bin/bash
set -e

CERT_DIR=/data/letsencrypt
WORK_DIR=/data/workdir
CONFIG_PATH=/data/options.json

EMAIL=$(jq --raw-output ".email" $CONFIG_PATH)
DOMAINS=$(jq --raw-output ".domains[]" $CONFIG_PATH)
KEYFILE=$(jq --raw-output ".keyfile" $CONFIG_PATH)
CERTFILE=$(jq --raw-output ".certfile" $CONFIG_PATH)
CFEMAIL=$(jq --raw-output ".cfemail" $CONFIG_PATH)
CFAPIKEY=$(jq --raw-output ".cfapikey" $CONFIG_PATH)

mkdir -p "$CERT_DIR"

echo "dns_cloudflare_email = \"$CFEMAIL\"" > $CERT_DIR/cf.ini
echo "dns_cloudflare_api_key = \"$CFAPIKEY\"" >> $CERT_DIR/cf.ini

chmod 640 $CERT_DIR/cf.ini

# Generate new certs
if [ ! -d "$CERT_DIR/live" ]; then
    DOMAIN_ARR=()
    for line in $DOMAINS; do
        DOMAIN_ARR+=(-d "$line")
    done

    echo "$DOMAINS" > /data/domains.gen
    certbot certonly --non-interactive --email "$EMAIL" --agree-tos --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" --dns-cloudflare --dns-cloudflare-credentials $CERT_DIR/cf.ini --preferred-challenges dns-01 "${DOMAIN_ARR[@]}" >&2
# Renew certs
else
    certbot renew --non-interactive --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" --dns-cloudflare --dns-cloudflare-credentials $CERT_DIR/cf.ini --preferred-challenges dns-01 >&2
fi

# copy certs to store
cp "$CERT_DIR"/live/*/privkey.pem "/ssl/$KEYFILE"
cp "$CERT_DIR"/live/*/fullchain.pem "/ssl/$CERTFILE"
