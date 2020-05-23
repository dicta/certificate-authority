# SSH host configuration

On machines that wil be logged into remotely via SSH, use the
`init_ssh_host.sh` script in the repository to provision them. This
script must be run as root.

When running `init_ssh_host.sh`, you'll have to select a provisioner to
use for the initial key provisioning. For the default provisioner, the
password to use is the one provided at CA setup time via the
`secrets/rootcert_pass.txt` configuration file. Production deployments
will use their own provisioner setups, the details of which are site-specific
and beyond the scope of this README.

# User configuration

On user machines, install the `ssh-agent` binary and `keychain` package.

In the user's `.bashrc` or similar file, add the following:

```text
# ssh-agent setup
eval $(keychain --systemd --quick --quiet)
```

Then, to get a user certificate for ssh login, just run the following command,
replacing `<username>` with the G Suite e-mail address for the user.

```text
step ssh login <username>
```
