#!/usr/bin/env bash
#
# Generic bash script helpers
#

. /etc/environment

COLOR_RED="$(tput -Txterm setaf 1)"
COLOR_GREEN="$(tput -Txterm setaf 2)"
COLOR_YELLOW="$(tput -Txterm setaf 3)"
COLOR_BLUE="$(tput -Txterm setaf 6)"
FONT_BOLD="$(tput -Txterm bold)"
FONT_RESET="$(tput -Txterm sgr0)"

MESSAGE_LOG_DIR='/var/log'
MESSAGE_TIMESTAMP=1

usage() {
  local SCRIPT="${1}"

  HELP_TEXT="$(awk '/^# Usage:/,/^$/ { sub(/^# ?/,"");if(i++)print s;s=$0; }' "${SCRIPT}")"

  echo
  output_message_format "${HELP_TEXT//\{SELF\}/${SCRIPT}}" 'green'
  echo
}

output_to_log() {
  local LOG_CONTENT="${1}"

  if [ ! -d "${MESSAGE_LOG_DIR}" ]; then
    mkdir -p "${MESSAGE_LOG_DIR}"
  fi

  if [[ -n "${OS_TYPE}" ]] && [[ "${OS_TYPE}" == 'mac' ]]; then
    if [[ -n "${MESSAGE_LOG_FILE}" ]]; then
      echo "${LOG_CONTENT}" >>"${MESSAGE_LOG_FILE}"
    fi
  else
    if [[ -n "${MESSAGE_LOG_FILE}" ]]; then
      echo "${LOG_CONTENT}" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" >>"${MESSAGE_LOG_FILE}"
    fi
  fi
}

output_date_format() {
  if [ -n "${MESSAGE_TIMESTAMP}" ]; then
    echo "[$(date +"%m-%d-%y %T")] "
  fi
}

confirm() {
  local CONFIRM_MESSAGE="${1}"

  while true; do
    read -r -p "${CONFIRM_MESSAGE} (yes/no) " ANSWER
    output_to_log "${CONFIRM_MESSAGE} (${ANSWER})"
    case ${ANSWER} in
    [Yy]*)
      break
      ;;
    [Nn]*)
      message_action ' - stopping'
      exit
      ;;
    *)
      message_notice 'Please answer yes or no.'
      ;;
    esac
  done
}

output_message_format() {
  local MESSAGE="${1}"
  local COLOR="${2}"
  local PREFIX="${3}"

  local COLOR_FORMAT=
  local PREFIX_TEXT=

  case "${COLOR}" in
  'yellow')
    COLOR_FORMAT="${COLOR_YELLOW}"
    ;;
  'green')
    COLOR_FORMAT="${COLOR_GREEN}"
    ;;
  'red')
    COLOR_FORMAT="${FONT_BOLD}${COLOR_RED}"
    ;;
  'blue')
    COLOR_FORMAT="${COLOR_BLUE}"
    ;;
  esac

  if [[ -n "${PREFIX}" ]]; then
    PREFIX_TEXT="[${PREFIX}] "
  fi

  echo "${COLOR_FORMAT}$(output_date_format)${PREFIX_TEXT}${MESSAGE}${FONT_RESET}"
}

message_action() {
  local MESSAGE="${1}"

  local OUTPUT_MESSAGE=
  OUTPUT_MESSAGE="$(output_message_format "${MESSAGE}" 'yellow' 'action')"

  output_to_log "${OUTPUT_MESSAGE}"
  echo "${OUTPUT_MESSAGE}"
}

message_ok() {
  local MESSAGE="${1}"

  local OUTPUT_MESSAGE=
  OUTPUT_MESSAGE="$(output_message_format "${MESSAGE}" 'green' 'ok')"

  output_to_log "${OUTPUT_MESSAGE}"
  echo "${OUTPUT_MESSAGE}"
}

message_notice() {
  local MESSAGE="${1}"

  local OUTPUT_MESSAGE=
  OUTPUT_MESSAGE="$(output_message_format "${MESSAGE}" 'blue')"

  output_to_log "${OUTPUT_MESSAGE}"
  echo "${OUTPUT_MESSAGE}"
}

message() {
  local MESSAGE="${1}"

  local OUTPUT_MESSAGE=
  OUTPUT_MESSAGE="$(output_message_format "${MESSAGE}")"

  output_to_log "${OUTPUT_MESSAGE}"
  echo "${OUTPUT_MESSAGE}"
}

message_error_notice() {
  local MESSAGE="${1}"

  local OUTPUT_MESSAGE=
  OUTPUT_MESSAGE="$(output_message_format "${MESSAGE}" 'red' 'error')"

  output_to_log "${OUTPUT_MESSAGE}"
  echo "${OUTPUT_MESSAGE}" >&2
}

message_error() {
  local MESSAGE="${1}"

  message_error_notice "${MESSAGE}"
  exit 1
}

check_argument() {
  local KEY="${1}"
  local VALUE="${2}"

  if [[ -z "${VALUE}" ]]; then
    message_error "${KEY} requires a value, current empty"
  fi
}
