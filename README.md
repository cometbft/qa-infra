# CometBFT Test Networks

This repo contains [Ansible] and [Terraform] scripts for spinning up CometBFT test networks on Digital Ocean (DO).

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
doctl auth init

# 2. Get the fingerprint of the SSH key you want to be associated with the root
#    user on the created VMs
doctl compute ssh-key list

# 3. Set up your Digital Ocean credentials as Terraform variables. Be sure to
#    write them to ./tf/terraform.tfvars as this file is ignored in .gitignore.
cat <<EOF > ./tf/terraform.tfvars
do_token = "dop_v1_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
ssh_keys = ["ab:cd:ef:01:23:45:67:89:ab:cd:ef:01:23:45:67:89"]
EOF

# 4. Initialize Terraform (only needed once)
make terraform-init

# 5. Create the VMs for the validators and Prometheus as specified in ./testnet.toml
#    Be sure to use your actual DO token and SSH key fingerprints for the DO_TOKEN
#    and DO_SSH_KEYS variables.
make terraform-apply

# 6. Discover the IP addresses of the hosts for Ansible
make hosts

# 7. Generate the testnet configuration
make configgen

# 8. Install all necessary software on the created VMs using Ansible
make ansible-install

# 9. Initialize the Prometheus instance
make prometheus-init

# 10. Start the test application on all of the validators
make start-network

# 11. Execute a load test against the network
#    This will start sending load until Ctrl-C is sent,
#    so consider running this in its own terminal
make runload

# 12. Once the execution is over, stop the network
make stop-network

# 13. Retrieve the data produced during the execution
# for the prometheus database
make retrieve-prometheus-data

# to retrieve the blockstore from a node
#    The target node from which the data is retrieved can be changed via RETRIEVE_TARGET_HOST.
#    The default value is "validator01"
make retrieve-block-store

#alternatively, to retrieve everything in one shot
make retrieve-data

```

## Additional Commands

### Restart the network

If you need to restart the running experiment, run the following command:

```sh
make restart
```

This command will delete all of the prometheus data, and re-initialize the nodes
on the network. The nodes will restart with the same configuration files and
IDs that they previously used, but all of their data will be deleted and reset.

## Metrics

Once you've completed setting up the network, take a look at your
`ansible/hosts` file for the IP address of the Prometheus server, then navigate
to that address on port 9090 in your web browser in order to query collected
metrics and view their associated graphs.

[Ansible]: https://docs.ansible.com/ansible/latest/index.html
[Terraform]: https://www.terraform.io/docs
[doctl]: https://docs.digitalocean.com/reference/doctl/how-to/install/
