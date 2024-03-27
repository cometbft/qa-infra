# Validators2 is a subset of validators that run a different version of CometBFT. They are the last
# `validators2_size` entries in the validators list.
variable "validators2_size" {
  type    = number
  default = 0
}

resource "local_file" "ansible_hosts" {
  depends_on = [
    digitalocean_droplet.testnet-node,
    digitalocean_droplet.testnet-prometheus,
    digitalocean_droplet.testnet-load-runner,
    digitalocean_droplet.ephemeral-node,
  ]
  filename = "../ansible/hosts"
  content = templatefile("${path.module}/templates/hosts.tmpl", {
    validators = slice(
      [for node in digitalocean_droplet.testnet-node : {
        name        = node.name,
        ip          = node.ipv4_address,
        internal_ip = node.ipv4_address_private
      }],
      # TODO: consider not including the validators2 set by setting the upper bound to (var.testnet_size - var.validators2_size)
      0, var.testnet_size
    )
    validators2 = slice(
      [for node in digitalocean_droplet.testnet-node : {
        name        = node.name,
        ip          = node.ipv4_address,
        internal_ip = node.ipv4_address_private
      }],
      var.testnet_size - var.validators2_size, var.testnet_size
    )
    ephemerals = [for node in digitalocean_droplet.ephemeral-node : {
      name        = node.name,
      ip          = node.ipv4_address,
      internal_ip = node.ipv4_address_private
    }]
    prometheus = {
      name        = digitalocean_droplet.testnet-prometheus.name,
      ip          = digitalocean_droplet.testnet-prometheus.ipv4_address,
      internal_ip = digitalocean_droplet.testnet-prometheus.ipv4_address_private
    }
    loadrunner = {
      name        = digitalocean_droplet.testnet-load-runner.name,
      ip          = digitalocean_droplet.testnet-load-runner.ipv4_address,
      internal_ip = digitalocean_droplet.testnet-load-runner.ipv4_address_private
    }
  })
}
