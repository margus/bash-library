#!/usr/bin/env bash

#
# Usage: {SELF} [-h|--help]
#
# After renew hook for certbot haproxy certificate generation
# If your HAProxy Certificates folder location is located somewhere else then export the path with the
# following variable
#   - HAPROXY_CERTS_DIR
#
# Options:
#        --verbose                      Verbose output
#   -h | --help                         Displays this help text

SCRIPT_NAME="${0}"
SCRIPT_FOLDER="$(dirname "${SCRIPT_NAME}")"

# shellcheck disable=SC1090
. "${SCRIPT_FOLDER}/helper.sh"

export MESSAGE_LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

CERTBOT_LIVE_DIR='/etc/letsencrypt/live'

if [[ -z "${HAPROXY_CERTS_DIR}" ]]; then
  HAPROXY_CERTS_DIR='/etc/haproxy/certs'
fi

VERBOSE=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  KEY="${1}"

  case "${KEY}" in
  -v | -vv | -vvv | --verbose)
    VERBOSE=1
    shift
    ;;
  -h | --help)
    usage "${0}"
    exit
    ;;
  -*)
    message_error "Incorrect key: ${KEY}"
    ;;
  *)
    POSITIONAL+=("${1}")
    shift
    ;;
  esac
done

set -- "${POSITIONAL[@]}"

if [ -n "${VERBOSE}" ]; then
  set -xv
fi

if [[ ! -d "${CERTBOT_LIVE_DIR}" ]]; then
  message_error 'Unable to find any certbot certs'
fi

if [[ ! -d "${HAPROXY_CERTS_DIR}" ]]; then
  mkdir -p "${HAPROXY_CERTS_DIR}"
fi

for CERT_PATH in "${CERTBOT_LIVE_DIR}"/*; do
  if [[ ! -d "${CERT_PATH}" ]]; then
    continue
  fi

  CERT="$(basename "${CERT_PATH}")"
  message_action "Generate Cert: ${CERT}"

  if [[ ! -f "${CERT_PATH}/fullchain.pem" ]] || [[ ! -f "${CERT_PATH}/privkey.pem" ]]; then
    message_error_notice 'Can not find correct fullchain and/or privkey'
    continue
  fi

  cat "${CERT_PATH}/fullchain.pem" "${CERT_PATH}/privkey.pem" >"${HAPROXY_CERTS_DIR}/${CERT}.pem"
done

HAPROXY_SERVICE_NAME="$(systemctl --plain | grep haproxy | awk '{print $1}')"
if [[ -n "${HAPROXY_SERVICE_NAME}" ]]; then
  systemctl reload "${HAPROXY_SERVICE_NAME}"
fi
