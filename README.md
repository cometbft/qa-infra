# Celestia Testnet Monitoring

This branch contains tools for administering the Celestia Testnet infrastructure
run by the Tendermint Core team.

## Working with these tools

There is a node in digital ocean at the moment that is running the Celestia code.
This node is connected to the Mamaki testnet and is running as a validator. The
process is running as a simple systemd job called `celestiad`.

The Celestia git repository is cloned on the node and can be rebuilt by running
the following make command:

`make rebuild`.

The Celestia repository on the host has been modified slightly to reference a
forked version of Tendermint that is also cloned on the host. The version of Tendermint
is actually a _fork of a fork_. Celestia maintains a fork of Tendermint called [celestia-core](https://github.com/celestiaorg/celestia-core), and this _fork_
has been forked so that changes can be pushed to the node without having to go
first through the Celestia repository. 

The code for the fork can be found in Interchain's [fork of celestia-core](https://github.com/interchainio/celestia-core). The rebuild make target pulls the fork down and rebuilds
using the forked code. Therefore, to quickly push fixes and changes to the node,
first edit and push the code into the `v035-testing` 
branch of the fork and then run `make rebuild` to deploy the changes. This will
also trigger a restart of the systemd process so the new code should come up
without much operator intervention.
