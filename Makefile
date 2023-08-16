ANSIBLE_SSH_RETRIES=5
EPHEMERAL_SIZE ?= 0
DO_INSTANCE_TAGNAME=v038-testnet
DO_VPC_SUBNET=172.19.144.0/20
LOAD_RUNNER_COMMIT_HASH ?= 51685158fe36869ab600527b852437ca0939d0cc
LOAD_RUNNER_CMD=go run github.com/cometbft/cometbft/test/e2e/runner@$(LOAD_RUNNER_COMMIT_HASH)
ANSIBLE_FORKS=150
export DO_INSTANCE_TAGNAME
export DO_VPC_SUBNET
export EPHEMERAL_SIZE
LOAD_CONNECTIONS ?= 2
LOAD_TX_RATE ?= 200
LOAD_TOTAL_TIME ?= 90
ITERATIONS ?= 5

# Set it to "all" to retrieve from all hosts
# Set it to "any" to retrieve from one full node
# Set it to the exact name of a validator to retrieve from it
RETRIEVE_TARGET_HOST ?= any
EXPERIMENT_DIR=$(shell date "+%Y-%m-%d-%H_%M_%S%N")

#VERSION_TAG ?= 3b783434f #v0.34.27 (cometbft/cometbft)
#VERSION_TAG ?= bef9a830e  #v0.37.alpha3 (cometbft/cometbft)
#VERSION_TAG ?= v0.38.0-alpha.2
#VERSION_TAG ?= e9abb116e #v0.38.alpha2 (cometbft/cometbft)
VERSION_TAG ?= 9fc711b6514f99b2dc0864fc703cb81214f01783 #vote extension sizes.
#VERSION_TAG ?= 7d8c9d426 #main merged into feature/abci++vef + bugfixes
#VERSION2_TAG ?= 66c2cb634 #v0.34.26 (informalsystems/tendermint)
VERSION_WEIGHT ?= 2
VERSION2_WEIGHT ?= 0

ifeq ($(VERSION_WEIGHT), 0)
$(error VERSION_WEIGHT must be non-zero)
endif

.PHONY: terraform-init
terraform-init:
	$(MAKE) -C ./tf/ init

.PHONY: terraform-apply
terraform-apply:
	$(MAKE) -C ./tf/ apply

.PHONY: hosts
hosts:
	echo "[validators]" > ./ansible/hosts
	doctl compute droplet list --tag-name "testnet-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3,4 | sort -k1 | sed 's/\(.*\) \(.*\) \(.*\)/\2 name=\1 internal_ip=\3/g' >> ./ansible/hosts
ifneq ($(VERSION2_WEIGHT), 0) #(num+den-1)/den is ceiling division
	echo "[validators2]" >> ./ansible/hosts
	total_validators=$$(doctl compute droplet list --tag-name "testnet-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3,4 | sort -k1 | sed 's/\(.*\) \(.*\) \(.*\)/\2 name=\1 internal_ip=\3/g' | wc -l) && \
	num=$$(( total_validators * $(VERSION2_WEIGHT) )) den=$$(( $(VERSION_WEIGHT)+$(VERSION2_WEIGHT) )) && \
	vals2=$$(( (num+den-1)/den )) && \
	doctl compute droplet list --tag-name "testnet-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3,4 | sort -k1 | sed 's/\(.*\) \(.*\) \(.*\)/\2 name=\1 internal_ip=\3/g' | tail -n $$vals2 >> ./ansible/hosts
endif
	echo "[prometheus]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "testnet-observability" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f3,4 | sed 's/\(.*\) \(.*\)/\1 internal_ip=\2/g' >> ./ansible/hosts
	echo "[loadrunners]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "testnet-load" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f3,4 | sed 's/\(.*\) \(.*\)/\1 internal_ip=\2/g' >> ./ansible/hosts
	echo "[ephemeral]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "ephemeral-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3,4 | sort -k1 | sed 's/\(.*\) \(.*\) \(.*\)/\2 name=\1 internal_ip=\3/g' >> ./ansible/hosts

.PHONY: configgen
configgen:
	./script/configgen.sh $(VERSION_TAG) ./ansible/hosts $(DO_VPC_SUBNET)

.PHONY: ansible-install
ansible-install:
	cd ansible && \
		ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts -u root install.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)" -e "vpc_subnet=$(DO_VPC_SUBNET)"
ifneq ($(VERSION2_WEIGHT), 0)
	cd ansible && \
		ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts --limit validators2 -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION2_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
endif

.PHONY: ansible-install-retry
ansible-install-retry:
	cd ansible && \
		ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i retry -u root install.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)" -e "vpc_subnet=$(DO_VPC_SUBNET)"
ifneq ($(VERSION2_WEIGHT), 0)
	cd ansible && \
		ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i retry --limit validators2 -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION2_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
endif

.PHONY: prometheus-init
prometheus-init:
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts  -u root prometheus.yaml -f 10

.PHONY: loadrunners-init
loadrunners-init:
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts -u root loadrunners-init.yaml -f 10

.PHONY: start-network
start-network:
	go run github.com/cometbft/cometbft/test/e2e/runner@$(VERSION_TAG) start -f ./ansible/testnet.toml --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json

.PHONY: stop-network
stop-network:
	go run github.com/cometbft/cometbft/test/e2e/runner@$(VERSION_TAG) stop -f ./ansible/testnet.toml --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json

.PHONY: runload
runload:
	cd ansible && \
		last_val=$$(ansible -i hosts --list-hosts validators | tail -1 | sed  "s/ //g") && \
		endpoints=$$(ansible-inventory -i hosts -y --host $$last_val | grep 'internal_ip' | cut -d ' ' -f2 | sed 's/\(.*\)/ws:\/\/\1:26657\/websocket/' | paste -s -d, -) && \
		ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook runload.yaml -i hosts -u root \
			-e endpoints=$$endpoints \
			-e connections=$(LOAD_CONNECTIONS) \
			-e time_seconds=$(LOAD_TOTAL_TIME) \
			-e tx_per_second=$(LOAD_TX_RATE) \
			-e iterations=$(ITERATIONS)

.PHONY: restart
restart:
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
ifneq ($(VERSION2_WEIGHT), 0)
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts --limit validators2 -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION2_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
endif
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook restart-prometheus.yaml -i hosts -u root
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook re-init-testapp.yaml -i hosts -u root -f $(ANSIBLE_FORKS)

.PHONY: rotate
rotate:
	./script/rotate.sh $(VERSION_TAG) `ansible all --list-hosts -i ./ansible/hosts --limit ephemeral | tail +2 | paste -s -d, - | tr -d ' '`

.PHONY: perturb-nodes
perturb-nodes:
	go run github.com/cometbft/cometbft/test/e2e/runner@$(VERSION_TAG) perturb -f ./ansible/testnet.toml --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json

.PHONY: retrieve-blockstore
retrieve-blockstore:
	mkdir -p "./experiments/$(EXPERIMENT_DIR)"
ifeq ($(RETRIEVE_TARGET_HOST), any)
	cd ansible && \
		last_val=$$(ansible -i hosts --list-hosts validators | tail -1 | sed  "s/ //g") && \
		retrieve_target_host=$$(ansible-inventory -i hosts -y --host $$last_val | grep 'name' | cut -d ' ' -f2) && \
		ansible-playbook -i hosts -u root retrieve-blockstore.yaml -e "dir=../experiments/$(EXPERIMENT_DIR)/" -e "target_host=$$retrieve_target_host"
else
	cd ansible && \
		ansible-playbook -i hosts -u root retrieve-blockstore.yaml -e "dir=../experiments/$(EXPERIMENT_DIR)/" -e "target_host=$(RETRIEVE_TARGET_HOST)"
endif

.PHONY: retrieve-prometheus-data
retrieve-prometheus-data:
	mkdir -p "./experiments/$(EXPERIMENT_DIR)"; \
	cd ansible && ansible-playbook -i hosts -u root retrieve-prometheus.yaml --limit `ansible -i hosts --list-hosts prometheus | tail -1 | sed  's/ //g'` -e "dir=../experiments/$(EXPERIMENT_DIR)/";

.PHONY: retrieve-data
retrieve-data: retrieve-prometheus-data retrieve-blockstore

.PHONY: terraform-destroy
terraform-destroy:
	$(MAKE) -C ./tf/ destroy
