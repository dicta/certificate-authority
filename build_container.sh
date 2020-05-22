#!/bin/sh

DIR=$(dirname $0)

# configuration (Google Suite authentication)
STEP_CA_VERSION="0.14.4"
STEP_CLI_VERSION="0.14.3"

docker build "${DIR}" \
    --build-arg STEP_CA_VERSION="${STEP_CA_VERSION}" \
    --build-arg STEP_CLI_VERSION="${STEP_CLI_VERSION}" \
    -t step-ca:latest

