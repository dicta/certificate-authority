#!/bin/bash
#
# This script will get an SSH host certificate from our CA and add a weekly
# cron job to rotate the host certificate.

# --- beginning of section requiring user configuration

# NOTE: Configure this for your domain based on your CA setup
#The URL of the certificate authority for the domain
CA_URL="https://example.com:443/"

# NOTE: Configure this for your domain based on your CA setup
# Obtain your CA fingerprint by running this on your CA:
#   # step certificate fingerprint $(step path)/certs/root_ca.crt
CA_FINGERPRINT="abcdefg"

# NOTE: This script was written for a set of machines running ArchLinux.
# On Arch, step-cli and step-ca were installed from the AUR packages
# "step-cli-bin" and "step-ca-bin", respectively. This installs the step
# CLI binary as "/usr/bin/step-cli", which is named differently than the "step"
# present if installing on Debian/Ubuntu or using the standalone binary package.
#
# If necessary, you can uncomment the following alias for use on these systems.
#
# alias step-cli=step

# --- end of section requiring user configuration

# Where the bootstrapped CA information will be stored
export STEPPATH=/etc/step-ca
mkdir -p $STEPPATH

# Configure `step` to connect to & trust our `step-ca`.
# Pull down the CA's root certificate so we can talk to it later with TLS
step-cli ca bootstrap --ca-url $CA_URL --fingerprint $CA_FINGERPRINT

# Install the CA cert for validating user certificates (from /etc/step-ca/certs/ssh_user_key.pub` on the CA).
step-cli ssh config --roots > $(step-cli path)/certs/ssh_user_key.pub

# Get an SSH host certificate

HOSTNAME=$(hostname)

# This helps us avoid a potential race condition / clock skew issue
# "x509: certificate has expired or is not yet valid: current time 2020-04-01T17:52:51Z is before 2020-04-01T17:52:52Z"
sleep 1

# Ask the CA to exchange our instance token for an SSH host certificate
step-cli ssh certificate $HOSTNAME /etc/ssh/ssh_host_ecdsa_key.pub \
    --host --sign --principal $HOSTNAME

# Configure and restart `sshd`
if [[ ! -d /etc/ssh/sshd_config.d ]]; then

mkdir -p /etc/ssh/sshd_config.d
echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config

tee -a /etc/ssh/sshd_config.d/step-ssh-ca.conf > /dev/null <<EOF
# SSH CA Configuration
# This is the CA's public key, for authenticating user certificates:
TrustedUserCAKeys $(step-cli path)/certs/ssh_user_key.pub

# This is our host private key and certificate:
HostKey /etc/ssh/ssh_host_ecdsa_key
HostCertificate /etc/ssh/ssh_host_ecdsa_key-cert.pub
EOF

fi

systemctl restart sshd


# Now add a weekly cron script to rotate our host certificate.
# This consists of two files, the service file that performs
# the rotation, and the timer file that schedules it. Only the timer
# file needs to be enabled via systemctl.

cat <<EOF > /etc/systemd/system/rotate-ssh-certificate.timer
[Unit]
Description=Rotate ssh host certificates on boot and weekly thereafter

[Timer]
OnBootSec=1min
OnUnitActiveSec=1w

[Install]
WantedBy=timers.target
EOF

cat <<EOF > /etc/systemd/system/rotate-ssh-certificate.service
[Unit]
Description=Rotate ssh host certificates provided from step-ca
After=network.service

[Service]
Type=oneshot
WorkingDiretory=/etc/ssh
Environment=STEPPATH=/etc/step-ca
ExecStart=/usr/bin/step-cli ssh renew ssh_host_ecdsa_key-cert.pub ssh_host_ecdsa_key --force
EOF

systemctl daemon-reload
systemctl enable rotate-ssh-certificate.timer
