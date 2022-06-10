# Tendermint Test Networks

This repo contains [Ansible] and [Terraform] scripts for spinning up Tendermint
test networks on Digital Ocean (DO).

## Requirements

- [Digital Ocean CLI][doctl]
- [Terraform CLI][Terraform]
- [Ansible CLI][Ansible]
- Go

## Instructions

After you have all the prerequisites installed and have configured your
[`testnet.toml`](./testnet.toml) file appropriately:

```bash
# 1. Set up your personal access token for DO
#    See https://docs.digitalocean.com/reference/api/create-personal-access-token/
doctl auth login

# 2. Get the fingerprint of the SSH key you want to be associated with the root
#    user on the created VMs
doctl compute ssh-key list

# 3. Initialize Terraform (only needed once)
make terraform-init

# 4. Create the VMs for the validators and Prometheus as specified in ./testnet.toml
#    Be sure to use your actual DO token and SSH key fingerprints for the DO_TOKEN
#    and DO_SSH_KEYS variables.
DO_TOKEN=dop_v1_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef \
    DO_SSH_KEYS=["ab:cd:ef:01:23:45:67:89:ab:cd:ef:01:23:45:67:89"] \
    make terraform-apply

# 5. Discover the IP addresses of the hosts for Ansible
make hosts

# 6. Generate the testnet configuration
make configgen

# 7. Install all necessary software on the created VMs using Ansible
make ansible-install

# 8. Initialize the Prometheus instance
make prometheus-init

# 9. Start the test application on all of the validators
make start-network
```

## Metrics

Once you've completed setting up the network, take a look at your
`ansible/hosts` file for the IP address of the Prometheus server, then navigate
to that address on port 9090 in order to query collected metrics and view
their associated graphs.

[Ansible]: https://docs.ansible.com/ansible/latest/index.html
[Terraform]: https://www.terraform.io/docs
[doctl]: https://docs.digitalocean.com/reference/doctl/how-to/install/
