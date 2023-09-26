# Setting up a Grafana server and dashboard

These are the instructions to install a Grafana server and to deploy a Grafana
dashboard connected to an existing Prometheus server.

## Requirements

- `ansible` v2.14+

## Installation

1. If needed, edit `ansible/group_vars/all.yml`, which contains the main
parameters to the ansible playbooks. 

    > Important: This file contains the default admin user and password, which
    > are created automatically when installing Grafana. If you need to run
    > Grafana in a public network, be sure to change and store the password in a
    > secure location.

2. Run `make` to install the Grafana server and to deploy the dashboard.
