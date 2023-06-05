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

1. Set up your [personal access token for DO](https://docs.digitalocean.com/reference/api/create-personal-access-token/)

    ```bash
    doctl auth init
    ```

    If you have executed this and the following steps before, you may be able to skip to step 5.
    And if your token expired, you may need to force the use of the one you just generated here by using `doctl auth init -t <new token>` instead.

    ```bash
    doctl auth init -t dop_v1_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    ```

2. Get the fingerprint of the SSH key you want to be associated with the root user on the created VMs

    ```bash
    doctl compute ssh-key list
    ```

3. Set up your Digital Ocean credentials as Terraform variables. Be sure to write them to `./tf/terraform.tfvars` as this file is ignored in `.gitignore`.

    ```bash
    cat <<EOF > ./tf/terraform.tfvars
    do_token = "dop_v1_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    ssh_keys = ["ab:cd:ef:01:23:45:67:89:ab:cd:ef:01:23:45:67:89"]
    EOF
    ```

4. Initialize Terraform (only needed once)

    ```bash
    make terraform-init
    ```

5. Create the VMs for the validators and Prometheus as specified in `./testnet.toml`   
    Be sure to use your actual DO token and SSH key fingerprints for the `do_token` and `do_ssh_keys` variables.

    ```bash
    make terraform-apply
    ```

6. Retrieve the IP addresses of the hosts for Ansible

    ```bash
    make hosts
    ```

7. Generate the testnet configuration

    ```bash
    make configgen
    ```

8. Install all necessary software on the created VMs using Ansible

    ```bash
    make ansible-install
    ```

9. Initialize the Prometheus instance

    ```bash
    make prometheus-init
    ```

10. Start the test application on all of the validators

    ```bash
    make start-network
    ```

11. Execute a load test against the network   
    This will start sending load until Ctrl-C is sent, so consider running this in its own terminal

    ```bash
    make runload
    ```

12. Once the execution is over, stop the network

    ```bash
    make stop-network
    ```

13. Retrieve the data produced during the execution.    
    You can either use the following command to retrieve both the prometheus and the blockstore databases together

    ```bash
    make retrieve-data
    ```

    To retrieve them independently use the following for prometheus, which will retrieve the data from all nodes.

    ```bash
    make retrieve-prometheus-data
    ```

    For blockstore, use the following. Here, notice that the target node from which the data is retrieved can be changed via the environment variable `RETRIEVE_TARGET_HOST`.
      - `"any"` (default) - retrieve from one random validator from the inventory.
      - `"all"` - retrieve from all nodes (very slow!);
      - set it to the exact name of a validator to retrieve from that particular validator.

    ```bash
    make retrieve-blockstore
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

### Destroy the network

Do not forget to destroy the experiment to stop charging.

```sh
make terraform-destroy
```

## Metrics

Once you've completed setting up the network, take a look at your
`ansible/hosts` file for the IP address of the Prometheus server, then navigate
to that address on port 9090 in your web browser in order to query collected
metrics and view their associated graphs.

[Ansible]: https://docs.ansible.com/ansible/latest/index.html
[Terraform]: https://www.terraform.io/docs
[doctl]: https://docs.digitalocean.com/reference/doctl/how-to/install/
