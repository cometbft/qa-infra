# Setting up a Grafana server and dashboards

These Ansible scripts will:
- install a Grafana server,
- deploy a Grafana data source connected to an existing Prometheus server, and
- deploy a list of Grafana dashboards (defined in `ansible/group_vars/all.yml`).

## Requirements

- `ansible` v2.14+

The scripts have been tested in MacOSX and Ubuntu 22.04.

## Installation

1. If needed, edit `ansible/group_vars/all.yml`, which contains the main
parameters to the ansible playbooks. 

    > Important: This file contains the default admin user and password, which
    > are created automatically when installing Grafana. If you need to run
    > Grafana in a public network, be sure to change and store the password in a
    > secure location.

2. Run `make` to install the Grafana server and to deploy the dashboards.
