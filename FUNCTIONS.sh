#!/usr/bin/env bash

set -e

# shellcheck source=./helpers/VERSIONS.sh
. "./VERSIONS.sh"

# shellcheck source=../homebrew-helpers/CONFIG.sh
. "../homebrew-helpers/CONFIG.sh"

function generate_cask() {
  if [ -n "${DEBUG}" ]; then
    echo
    echo "PRODUCT_NAME:             ${PRODUCT_NAME}"
    echo "PRODUCT_VERSION:          ${PRODUCT_VERSION}"
    echo "PRODUCT_VERSION_CLEAN     ${PRODUCT_VERSION_CLEAN}"
    echo "PRODUCT_BUILD:            ${PRODUCT_BUILD}"
    echo "PRODUCT_ARCHITECTURE:     ${PRODUCT_ARCHITECTURE}"
    echo "PRODUCT_FLAGS:            ${PRODUCT_FLAGS}"
    echo "PRODUCT_PACKAGE_PATH:     ${PRODUCT_PACKAGE_PATH}"
    echo "PRODUCT_CHECKSUM_URL:     ${PRODUCT_CHECKSUM_URL}"
    echo "PRODUCT_CHECKSUM_PATTERN: ${PRODUCT_CHECKSUM_PATTERN}"
  fi

  # fail if required argument is unset
  if [[ -z ${PRODUCT_NAME} || -z ${PRODUCT_VERSION} || -z ${PRODUCT_CHECKSUM_URL} || -z ${PRODUCT_CHECKSUM_PATTERN} ]]; then
    echo "missing required argument"
    exit 1
  fi

  # omit PRODUCT_ARCHITECTURE string if positional argument calls for it
  if [[ -n ${PRODUCT_ARCHITECTURE} && ${PRODUCT_ARCHITECTURE} == "omit" ]]; then
    PRODUCT_ARCHITECTURE=""
  fi

#  echo "curl --get --location --silent "${PRODUCT_CHECKSUM_URL}" | grep "${PRODUCT_CHECKSUM_PATTERN}" | cut -f 1 -d " ""

  # create temporary file for checksum data
  PRODUCT_CHECKSUM_FILE=$(mktemp)

  # fetch checksums file
  curl \
    --get \
    --location \
    --output "${PRODUCT_CHECKSUM_FILE}" \
    --silent \
    "${PRODUCT_CHECKSUM_URL}"

  # "parse" checksum file and assign value
  PRODUCT_CHECKSUM=$(cat ${PRODUCT_CHECKSUM_FILE} | grep ${PRODUCT_CHECKSUM_PATTERN} | cut -f 1 -d ' ')

  if [[ -z ${PRODUCT_CHECKSUM} ]]; then
    echo "unable to set CHECKSUM"
    exit 1
  else
    if [ -n "${DEBUG}" ]; then
    echo "PRODUCT_CHECKSUM_FILE:    ${PRODUCT_CHECKSUM_FILE}"
    echo "PRODUCT_CHECKSUM:         ${PRODUCT_CHECKSUM}"
    fi
  fi

  rm -f "${GENERATED_CASKS_DIR}/${PRODUCT_NAME}@${PRODUCT_VERSION}.rb"

  # generate Cask file
  sed \
    -e "s/%%PRODUCT_VERSION%%/${PRODUCT_VERSION}/g" \
    -e "s/%%PRODUCT_VERSION_CLEAN%%/${PRODUCT_VERSION_CLEAN}/g" \
    -e "s/%%PRODUCT_BUILD%%/${PRODUCT_BUILD}/g" \
    -e "s/%%PRODUCT_ARCHITECTURE%%/${PRODUCT_ARCHITECTURE}/g" \
    -e "s/%%PRODUCT_FLAGS%%/${PRODUCT_FLAGS}/g" \
    -e "s/%%PRODUCT_PACKAGE_PATH%%/${PRODUCT_PACKAGE_PATH}/g" \
    -e "s/%%PRODUCT_CHECKSUM%%/${PRODUCT_CHECKSUM}/g" \
    "templates/${PRODUCT_NAME}.cask" \
    > "${GENERATED_CASKS_DIR}/${PRODUCT_NAME}@${PRODUCT_VERSION_CLEAN}.rb"
}

