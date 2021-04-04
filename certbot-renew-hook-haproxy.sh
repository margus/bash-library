#!/usr/bin/env bash
#
# After renew hook for certbot for haproxy
#

CERTBOT_LIVE_FOLER='/etc/letsencrypt/live'
HAPROXY_CERTS='/etc/haproxy/certs'

if [[ ! -d "${CERTBOT_LIVE_FOLER}" ]]; then
    echo 'Unable to find any certbot certs'
    exit 1
fi

if [[ ! -d "${HAPROXY_CERTS}" ]]; then
    mkdir -p "${HAPROXY_CERTS}"
fi

for CERT_PATH in "${CERTBOT_LIVE_FOLER}"/*; do
    if [[ ! -d "${CERT_PATH}" ]]; then
        continue
    fi

    CERT="$(basename "${CERT_PATH}")"
    echo "Cert: ${CERT}"

    if [[ ! -f "${CERT_PATH}/fullchain.pem" ]] || [[ ! -f "${CERT_PATH}/privkey.pem" ]]; then
        echo 'Can not find correct fullchain and/or privkey'
        continue
    fi

    cat "${CERT_PATH}/fullchain.pem" "${CERT_PATH}/privkey.pem" > "${HAPROXY_CERTS}/${CERT}.pem"
done

HAPROXY_SERVICE_NAME="$(systemctl --plain |grep haproxy |awk '{print $1}')"
if [[ -n "${HAPROXY_SERVICE_NAME}" ]]; then
    systemctl reload "${HAPROXY_SERVICE_NAME}"
fi
