resource "digitalocean_project" "celestia-testnet" {
  name        = "celestia-nodes"
  description = "A project to test the Tendermint running with Celestia."
  resources = [digitalocean_droplet.celestia-node.urn, digitalocean_droplet.testnet-prometheus.urn]
}
