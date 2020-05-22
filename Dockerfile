FROM alpine:latest

# Setup build arguments, specified using "docker build --build-arg"
ARG STEP_CA_VERSION
ARG STEP_CLI_VERSION

RUN apk add bash curl dpkg sed \
  && curl -sLO https://github.com/smallstep/certificates/releases/download/v${STEP_CA_VERSION}/step-certificates_${STEP_CA_VERSION}_amd64.deb \ 
  && curl -sLO https://github.com/smallstep/cli/releases/download/v${STEP_CLI_VERSION}/step-cli_${STEP_CLI_VERSION}_amd64.deb \ 
  && dpkg --force-architecture -i step-certificates_${STEP_CA_VERSION}_amd64.deb \
  && dpkg --force-architecture -i step-cli_${STEP_CLI_VERSION}_amd64.deb

COPY start_step_sshca.sh /

CMD /bin/bash -c /start_step_sshca.sh
