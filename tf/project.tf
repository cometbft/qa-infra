resource "digitalocean_project" "celestia-node" {
  name        = "celestia-node"
  description = "A project to test the Tendermint running with Celestia."
  resources = [digitalocean_droplet.celestia-node.urn, digitalocean_droplet.testnet-prometheus.urn]
}
