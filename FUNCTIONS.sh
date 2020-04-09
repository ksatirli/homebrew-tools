#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091


# shellcheck disable=SC1091
. "../homebrew-tools/CONFIG.sh"

function generate_cask() {
  if [ -z "${VERSION_CLEAN}" ];
  then
    VERSION_CLEAN="${VERSION}"
  fi

  if [ -n "${DEBUG}" ]; then
    echo
    echo "BINARY:           ${BINARY}"
    echo "VERSION:          ${VERSION}"
    echo "VERSION_CLEAN     ${VERSION_CLEAN}"
    echo "BUILD:            ${BUILD}"
    echo "FLAGS:            ${FLAGS}"
    echo "PACKAGE_PROTOCOL: ${PACKAGE_PROTOCOL}"
    echo "PACKAGE_HOST:     ${PACKAGE_HOST}"
    echo "PACKAGE_PATH:     ${PACKAGE_PATH}"
    echo "CHECKSUM_URL:     ${CHECKSUM_URL}"
    echo "CHECKSUM_PATTERN: ${CHECKSUM_PATTERN}"
    echo "NAME:             ${NAME}"
    echo "HOMEPAGE:         ${HOMEPAGE}"
  fi

  # fail if required argument is unset
  if [[ -z ${BINARY} || -z ${VERSION} || -z ${CHECKSUM_URL} || -z ${CHECKSUM_PATTERN} ]]; then
    echo "missing required argument"
    exit 1
  fi

  # omit ARCHITECTURE string if positional argument calls for it
  if [[ -n ${ARCHITECTURE} && ${ARCHITECTURE} == "omit" ]]; then
    ARCHITECTURE=""
  fi

  # create temporary file for checksum data
  CHECKSUM_FILE=$(mktemp)

  # fetch checksums file
  curl \
    --get \
    --location \
    --output "${CHECKSUM_FILE}" \
    --silent \
    "${CHECKSUM_URL}"

  # "parse" checksum file and assign value
  # shellcheck disable=SC2086
  CHECKSUM=$(grep ${CHECKSUM_PATTERN} < "${CHECKSUM_FILE}" | cut -f 1 -d ' ')

  if [[ -z ${CHECKSUM} ]]; then
    echo "unable to set CHECKSUM"
    exit 1
  else
    if [ -n "${DEBUG}" ]; then
    echo "CHECKSUM_FILE:    ${CHECKSUM_FILE}"
    echo "CHECKSUM:         ${CHECKSUM}"
    fi
  fi

  rm -f "${GENERATED_CASKS_DIR}/${NAME}@${VERSION}.rb"

  # generate Cask file
  sed \
    -e "s/%%BINARY%%/${BINARY}/g" \
    -e "s/%%VERSION%%/${VERSION}/g" \
    -e "s/%%VERSION_CLEAN%%/${VERSION_CLEAN}/g" \
    -e "s/%%BUILD%%/${BUILD}/g" \
    -e "s/%%FLAGS%%/${FLAGS}/g" \
    -e "s/%%PACKAGE_PROTOCOL%%/${PACKAGE_PROTOCOL}/g" \
    -e "s/%%PACKAGE_HOST%%/${PACKAGE_HOST}/g" \
    -e "s/%%PACKAGE_PATH%%/${PACKAGE_PATH}/g" \
    -e "s/%%CHECKSUM%%/${CHECKSUM}/g" \
    -e "s/%%NAME%%/${NAME}/g" \
    -e "s/%%HOMEPAGE%%/${HOMEPAGE}/g" \
    "${CASK_FILE}" \
    > "${GENERATED_CASKS_DIR}/${BINARY}@${VERSION_CLEAN}.rb"

    # clean up
    unset VERSION VERSION_CLEAN BUILD ARCHITECTURE FLAGS CHECKSUM_PATTERN
}

function verify_cask() {
  if [ -z "${VERSION_CLEAN}" ];
  then
    VERSION_CLEAN="${VERSION}"
  fi

 if [ -n "${DEBUG}" ]; then
   echo
   echo "NAME:          ${NAME}"
   echo "VERSION_CLEAN: ${VERSION_CLEAN}"
 fi

 # fail if required argument is unset
 if [[ -z ${NAME} || -z ${VERSION_CLEAN} ]]; then
   echo "missing required argument"
   exit 1
 fi

 # create Casks directory if it does not exist
 mkdir -p "${UPSTREAM_CASKS_DIR}/"

 # replace tapped (upstream) Cask with locally available version
 rm -f "${UPSTREAM_CASKS_DIR}/${NAME}@${VERSION_CLEAN}.rb"
 cp "${GENERATED_CASKS_DIR}/${NAME}@${VERSION_CLEAN}.rb" "${UPSTREAM_CASKS_DIR}/"

 # install Cask
 brew cask install --force "${NAME}@${VERSION_CLEAN}"

 # audit Cask
 brew cask audit "${NAME}@${VERSION_CLEAN}"

 # check Cask style
 brew cask style "${NAME}@${VERSION_CLEAN}"

 # uninstall Cask
 brew cask uninstall --force "${NAME}@${VERSION_CLEAN}"

 # clean up
 unset VERSION VERSION_CLEAN
}
