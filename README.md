# Tendermint Test Networks

This repo contains [Ansible] and [Terraform] scripts for spinning up Tendermint
test networks on Digital Ocean (DO).

## Requirements

- [Digital Ocean CLI][doctl]
- [Terraform CLI][Terraform]
- [Ansible CLI][Ansible]
- Go

## Deployment

After you have all the prerequisites installed and have configured your
[`testnet.toml`](./testnet.toml) file appropriately:

```bash
# 1. Set up your personal access token for DO
#    See https://docs.digitalocean.com/reference/api/create-personal-access-token/
doctl auth login

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
make init

# 5. Create the VMs for the validators and monitoring server as specified in
#    ./testnet.toml
make deploy

# 6. Execute a load test against the network
make runload
```

## Data visualization

Once you have deployed a testnet, there will be a "monitor" server available
running an [InfluxDB] instance. Check the generated `ansible/hosts` file for the
IP address of the monitor and navigate to `http://<monitor-ip>:8086` in your web
browser to access the InfluxDB interface.

The username is `admin` and the password is automatically generated during
deployment. The password can be found in the `ansible/secrets.yaml` file (not
committed to the repository).

The UI is relatively straightforward, but if you need additional help please
see the [InfluxDB docs][InfluxDB].

## Reloading the test app

In cases where you don't want to tear down the infrastructure and only want to
reload the test app running across the network (say there are new changes on the
`v0.35.x` branch in the Git repo):

```bash
make update-testapp
```

This will stop the test app, remove all config and data, redeploy the config,
and restart the test app.

## Teardown

To destroy all Digital Ocean infrastructure:

```bash
make destroy
```

## Metrics

Once you've completed setting up the network, take a look at your
`ansible/hosts` file for the IP address of the Prometheus server, then navigate
to that address on port 9090 in your web browser in order to query collected
metrics and view their associated graphs.

[Ansible]: https://docs.ansible.com/ansible/latest/index.html
[Terraform]: https://www.terraform.io/docs
[doctl]: https://docs.digitalocean.com/reference/doctl/how-to/install/
[InfluxDB]: https://docs.influxdata.com/influxdb/v2.2/
