#!/bin/sh

# shellcheck disable=SC2034
REPOSITORY_ORG="operatehappy"
REPOSITORY_NAME="$(basename "$(pwd)")"
GENERATED_CASKS_DIR="Casks"
UPSTREAM_CASKS_DIR="$(brew --repo)/Library/Taps/${REPOSITORY_ORG}/${REPOSITORY_NAME}/Casks"
