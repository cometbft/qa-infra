resource "local_file" "infrastructure_data" {
  depends_on = [
    digitalocean_droplet.testnet-node,
    digitalocean_droplet.testnet-prometheus,
    digitalocean_droplet.testnet-load-runner,
    digitalocean_droplet.ephemeral-node,
  ]
  content = templatefile("${path.module}/templates/infrastructure-data.json.tmpl", {
    subnet = var.vpc_subnet,
    nodes = [for node in concat(digitalocean_droplet.testnet-node, digitalocean_droplet.ephemeral-node, [digitalocean_droplet.testnet-prometheus], [digitalocean_droplet.testnet-load-runner]) : {
        name        = node.name,
        ip          = node.ipv4_address,
        internal_ip = node.ipv4_address_private
      }]
  })
  filename = "../ansible/testnet/infrastructure-data.json"
}
