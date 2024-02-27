include experiment.mk

ifndef MANIFEST_PATH
	$(error MANIFEST_PATH is not set)
endif

ifndef VERSION_TAG
	$(error VERSION_TAG is not set)
endif

ifndef VERSION_WEIGHT
	$(error VERSION_WEIGHT is not set)
endif

ifeq ($(VERSION_WEIGHT), 0)
	$(error VERSION_WEIGHT must be non-zero)
endif

RUNNER_COMMIT_HASH ?= $(VERSION_TAG)
LOAD_RUNNER_CMD=go run github.com/cometbft/cometbft/test/e2e/runner@$(RUNNER_COMMIT_HASH)
ANSIBLE_SSH_RETRIES=5
ANSIBLE_FORKS=150
export DO_INSTANCE_TAGNAME
export DO_VPC_SUBNET
export EPHEMERAL_SIZE
export MANIFEST_PATH
export VERSION_WEIGHT
export VERSION2_WEIGHT

# Set it to "all" to retrieve from all hosts
# Set it to "any" to retrieve from one full node
# Set it to the exact name of a validator to retrieve from it
RETRIEVE_TARGET_HOST ?= any
EXPERIMENT_DIR ?= $(shell date "+%Y-%m-%d-%H_%M_%S%N")

.PHONY: terraform-init
terraform-init:
	$(MAKE) -C ./tf/ init

.PHONY: terraform-apply
terraform-apply:
	$(MAKE) -C ./tf/ apply

.PHONY: configgen
configgen:
	./script/configgen.sh $(RUNNER_COMMIT_HASH) $(MANIFEST)

.PHONY: ansible-install
ansible-install:
	cd ansible && \
		ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts -u root testapp-install.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)" -e "vpc_subnet=$(DO_VPC_SUBNET)"
ifneq ($(VERSION2_WEIGHT), 0)
	cd ansible && \
		ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts --limit validators2 -u root testapp-update.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION2_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
endif

.PHONY: prometheus-init
prometheus-init:
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts  -u root prometheus-init.yaml -f 10

.PHONY: loadrunners-init
loadrunners-init:
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts -u root loader-init.yaml -f 10

.PHONY: start-network
start-network:
	go run github.com/cometbft/cometbft/test/e2e/runner@$(RUNNER_COMMIT_HASH) start \
		-f $(MANIFEST_PATH) --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json

.PHONY: stop-network
stop-network:
	go run github.com/cometbft/cometbft/test/e2e/runner@$(RUNNER_COMMIT_HASH) stop \
		-f $(MANIFEST_PATH) --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json

.PHONY: runload
runload:
	cd ansible && \
		endpoints=$$(scripts/get-endpoints.sh) && \
		ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook loader-run.yaml -i hosts -u root \
			-e endpoints=$$endpoints \
			-e connections=$(LOAD_CONNECTIONS) \
			-e time_seconds=$(LOAD_TOTAL_TIME) \
			-e tx_per_second=$(LOAD_TX_RATE) \
			-e iterations=$(ITERATIONS)

.PHONY: restart
restart:
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts -u root testapp-update.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
ifneq ($(VERSION2_WEIGHT), 0)
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook -i hosts --limit validators2 -u root testapp-update.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION2_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
endif
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook prometheus-restart.yaml -i hosts -u root
	cd ansible && ANSIBLE_SSH_RETRIES=$(ANSIBLE_SSH_RETRIES) ansible-playbook testapp-reinit.yaml -i hosts -u root -f $(ANSIBLE_FORKS)

.PHONY: rotate
rotate:
	./script/rotate.sh $(RUNNER_COMMIT_HASH) $(MANIFEST_PATH) \
		`ansible all --list-hosts -i ./ansible/hosts --limit ephemeral | tail +2 | paste -s -d, - | tr -d ' '`

.PHONY: perturb-nodes
perturb-nodes:
	go run github.com/cometbft/cometbft/test/e2e/runner@$(RUNNER_COMMIT_HASH) perturb \
		-f $(MANIFEST_PATH) --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json

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
