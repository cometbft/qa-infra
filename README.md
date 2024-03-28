# CometBFT Test Networks

This repo contains [Ansible] and [Terraform] scripts for spinning up CometBFT test networks on Digital Ocean (DO).

## Requirements

- [Digital Ocean CLI][doctl]
- [Terraform CLI][Terraform]
- [Ansible CLI][Ansible]
- Go

## Instructions

### Setup

After you have all the prerequisites installed:

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

### Start the network

After you have set up the infrastructure, you need to setup the experiment.
There are two ways of doing this, using the script `scripts/runtests.py` to automates part of it or not.

#### Using `scripts/runtests.py` 

Execute the script once to update your experiment setup according to your templates.  
Use the `-s` flag to run it just once, as in the following.

    ```bash
    python3 runtests.py -l log.log -o flood_options.json -s
    ```

1. Create the VMs for the validators and Prometheus as specified in the manifest file.
    Be sure to use your actual DO token and SSH key fingerprints for the `do_token` and `do_ssh_keys` variables.

    ```bash
    make terraform-apply
    ```
    
    After creating the DO droplets, this command will generate two files with information about the
    IP addresses of the nodes: an Ansible inventory file `./ansible/hosts`, and
    `./ansible/testnet/infrastructure-data.json` for E2E's `runner` tool.

2. Generate the testnet configuration, using the updated scripts

    ```bash
    make configgen
    ```

3. Install all necessary software on the created VMs using Ansible

    ```bash
    make ansible-install
    ```

4. Initialize the Prometheus instance

    ```bash
    make prometheus-init
    ```


#### Without the script

5. Set up the test you will run in the `experiment.mk` file:
    1. Set the path to your manifest file in the variable `MANIFEST`.
    2. Set the commit hash of CometBFT that you to install in the nodes in the variable `VERSION_TAG`.
    3. If you want to deploy a subset of the validators with a different version of CometBFT, set
       the variable `VERSION2_TAG` to the commit hash you want to install in that subset. Then set
       the proportion of nodes that will run `VERSION_TAG` and `VERSION2_TAG` in the variables
       `VERSION_WEIGHT` and `VERSION2_WEIGHT` respectively.
    4. If necessary, set the variables `DO_INSTANCE_TAGNAME` and `DO_VPC_SUBNET` to customized
       values to prevent collisions with other QA runs, including possible other users of the
       DigitalOcean project who might be running these scripts. If the subnet is allocated in the
       private IP address range 172.16.0.0/12, as it is in the unmodified file, a good choice should be
       in the range 172.16.16.0/20 - 172.31.240.0/20. You may also need to rename the DO project
    `cmt-testnet` in the `tf/project.tf` file to a unique name.

6. Create the VMs for the validators and Prometheus as specified in the manifest file.
    Be sure to use your actual DO token and SSH key fingerprints for the `do_token` and `do_ssh_keys` variables.

    ```bash
    make terraform-apply
    ```
    
    After creating the DO droplets, this command will generate two files with information about the
    IP addresses of the nodes: an Ansible inventory file `./ansible/hosts`, and
    `./ansible/testnet/infrastructure-data.json` for E2E's `runner` tool.

    Note that installing packages defined in `tf/user-data.txt` may take more time than expected.
    It's possible that the installation process has not yet finished even when DO says that droplets
    have been created successfully.

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

### Execute the load test
If you are using `script/runtests.py`, run it now.

    ```bash
    python3 runtests.py -l log.log -o flood_options.json
    ```

If you are not using the script, first nitialize the load-runner node, if not it's yet running:

```bash
make loadrunners-init
```

The following command will start sending load until Ctrl-C is sent, so consider running this in its own terminal:

```bash
make runload
```

### Stop the network and retrieve data

11. Once the execution is over, stop the network:

    ```bash
    make stop-network
    ```

12. Retrieve the data produced during the execution.
    If you have used `runtests.py`, the data may have been retrieved already. 
    Otherwise, you can either use the following command to retrieve both the prometheus and the blockstore databases together

    ```bash
    make retrieve-data
    ```

    or, to retrieve them independently, use the following for prometheus, which will retrieve the data from all nodes,

    ```bash
    make retrieve-prometheus-data
    ```

    and, for the blockstore, use the following. Here, notice that the target node from which the data is retrieved can be changed via the environment variable `RETRIEVE_TARGET_HOST`.
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
# Modify your testnet.toml file
# Update the configuration files locally
make configgen
# Update the configuration files and restart CometBFT in the nodes
make restart
# Reset and restart prometheus
make restart-prometheus
```

This command will delete all of the prometheus data, and re-initialize the nodes
on the network. The nodes will restart with the new configuration and all of their
data will be deleted and reset, but they will use the same IDs that they previously used.

If you do not want to update the configuration files and rerun experiments with same
configuration, you can omit the `make configgen` step.

If you are want to collect the metrics of multiple experiments on the same prometheus database
you can omit the `make restart-prometheus` command.

### Destroy the network

Do not forget to destroy the experiment to stop charging.

```sh
make terraform-destroy
```

#### Keep the Prometheus node running

You may want to keep running some nodes to retrieve data from them and destroy the others.
The following commands will destroy all nodes except the Prometheus node and the last validator.
```
cd tf && terraform state rm digitalocean_droplet.testnet-prometheus digitalocean_droplet.testnet-node[199]
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
