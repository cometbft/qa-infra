resource "local_file" "ansible_inventory" {
  content = templatefile("hosts.tftpl", {
    nodes = digitalocean_droplet.node.*,
    monitor = digitalocean_droplet.monitor,
  })
  filename = "../ansible/hosts"
}
