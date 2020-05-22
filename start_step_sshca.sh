#!/bin/bash
#
# This script will configure and launch a step-ca SSH Certificate Authority.

. /ca-secrets/init-environment

OPENID_CONFIG_ENDPOINT="https://accounts.google.com/.well-known/openid-configuration"

# All your CA config and certificates will go into $STEPPATH.
export STEPPATH=/ca
mkdir -p $STEPPATH
chmod 700 $STEPPATH

if [[ ! -f "/ca/.ca_init_complete" ]]
then

    echo "Performing first-time setup of certificate authority."

    # Set up our basic CA configuration and generate root keys
    /usr/bin/step ca init --ssh \
        --name="${CA_NAME}" \
        --provisioner="${CA_ADMIN_EMAIL}" \
        --dns="${CA_IP_ADDR},${CA_HOSTNAME}" \
        --address=":443" \
        --password-file=/ca-secrets/rootcert-pass.txt

    # Add the Google OAuth provisioner, for user certificates
    /usr/bin/step ca provisioner add "google-${GSUITE_DOMAIN}" --type=oidc --ssh \
        --client-id="${OIDC_CLIENT_ID}" \
        --client-secret="${OIDC_CLIENT_SECRET}" \
        --configuration-endpoint="${OPENID_CONFIG_ENDPOINT}" \
        --domain="${GSUITE_DOMAIN}"

    # The sshpop provisioner lets hosts renew their ssh certificates
    /usr/bin/step ca provisioner add SSHPOP --type=sshpop --ssh

    # Use Google (OIDC) as the default provisioner in the end user's
    # ssh configuration template.
    /bin/sed -i 's/\%p$/%p --provisioner="google-${GSUITE_DOMAIN}"/g' /ca/templates/ssh/config.tpl

    echo "export STEPPATH=$STEPPATH" >> /etc/profile.d/step-ca-path.sh

    # Create a file to let the next run know that initialization has already been done.
    touch /ca/.ca_init_complete
fi

echo "Launching step-ca..."
/usr/bin/step-ca /ca/config/ca.json --password-file=/ca-secrets/rootcert-pass.txt
