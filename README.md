# Initial Certificate Authority configuration

This repo contains a certificate authority that runs standalone in a Docker container. To build the 
container, run `build-container.sh`. This is configurable to select the version of the Smallstep
CLI and CA tools to install. When you first start the container, an initial setup process
will run to create the necessary root certificate and key material, and configure the
provisioner for using G Suite for user authentication out of the box.

To set this up, before you run the container for the first time, check out the files in
the `secrets.example/`folder, configure them for your domain's settings, and place the
resulting configured files in a new folder named `secrets/`. Do not commit the material
in the `secrets/` folder to revision control!.

Once configured, you can start up the container using the included `docker-compose`
configuration file by typing the following:

```
docker-compose up
```

This should start up, go through the initial CA configuration, and print the fingerprint
of the root certificate to the screen. Save this, as you'll need it for all of the
client and SSH host setup to follow.

For more information (and the source of most of the code here), please see 
[this Smallstep tutorial](https://smallstep.com/blog/diy-single-sign-on-for-ssh/).

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
