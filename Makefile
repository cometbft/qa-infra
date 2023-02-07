EPHEMERAL_SIZE ?= 0
DO_INSTANCE_TAGNAME=v037-testnet
LOAD_RUNNER_COMMIT_HASH ?= 51685158fe36869ab600527b852437ca0939d0cc
LOAD_RUNNER_CMD=go run github.com/cometbft/cometbft/test/e2e/runner@$(LOAD_RUNNER_COMMIT_HASH)
ANSIBLE_FORKS=20
export DO_INSTANCE_TAGNAME
export EPHEMERAL_SIZE
ROTATE_CONNECTIONS ?= 2
ROTATE_TX_RATE ?= 200
ROTATE_TOTAL_TIME ?= 90

# Set it to "all" to retrieve from all hosts
# Set it to "any" to retrieve from one full node
# Set it to the exact name of a validator to retrieve from it
RETRIEVE_TARGET_HOST ?= any
EXPERIMENT_DIR=$(shell date "+%Y-%m-%d-%H_%M_%S%N")

VERSION_TAG ?= 3b783434f #v0.34.27 (cometbft/cometbft)
VERSION_TAG2 ?= 66c2cb634 #v0.34.26 (informalsystems/tendermint)
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
	doctl compute droplet list --tag-name "testnet-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' >> ./ansible/hosts
ifneq ($(VERSION2_WEIGHT), 0) #(num+den-1)/den is ceiling division
	echo "[validators2]" >> ./ansible/hosts
	total_validators=$$(doctl compute droplet list --tag-name "testnet-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' | wc -l) && \
	num=$$(( total_validators * $(VERSION2_WEIGHT) )) den=$$(( $(VERSION_WEIGHT)+$(VERSION2_WEIGHT) )) && \
	vals2=$$(( (num+den-1)/den )) && \
	doctl compute droplet list --tag-name "testnet-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' | tail -n $$vals2 >> ./ansible/hosts
endif
	echo "[prometheus]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "testnet-observability" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f3   >> ./ansible/hosts
	echo "[loadrunners]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "testnet-load" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f3   >> ./ansible/hosts
	echo "[ephemeral]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "ephemeral-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' >> ./ansible/hosts

.PHONY: configgen
configgen:
	./script/configgen.sh $(VERSION_TAG) ./ansible/hosts

.PHONY: ansible-install
ansible-install:
	cd ansible && \
		ansible-playbook -i hosts -u root base.yaml -f $(ANSIBLE_FORKS) && \
		ansible-playbook -i hosts -u root prometheus-node-exporter.yaml -f $(ANSIBLE_FORKS) && \
		ansible-playbook -i hosts -u root init-testapp.yaml -f $(ANSIBLE_FORKS) && \
		ansible-playbook -i hosts -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
ifneq ($(VERSION2_WEIGHT), 0)
	cd ansible && \
		ansible-playbook -i hosts --limit validators2 -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG2)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
endif

.PHONY: prometheus-init
prometheus-init:
	cd ansible && ansible-playbook -i hosts  -u root prometheus.yaml -f 10

.PHONY: start-network
start-network:
	cd ansible && ansible-playbook -i hosts -u root start-testapp.yaml -f $(ANSIBLE_FORKS)

.PHONY: stop-network
stop-network:
	cd ansible && ansible-playbook -i hosts -u root stop-testapp.yaml -f $(ANSIBLE_FORKS)

.PHONY: runload
runload:
	cd ansible &&  ansible-playbook runload.yaml -i hosts -u root \
		-e endpoints=`ansible -i ./hosts --list-hosts validators | tail +2 | tail -1 | sed  "s/ //g" | sed 's/\(.*\)/ws:\/\/\1:26657\/websocket/' | paste -s -d, -` \
		-e connections=$(ROTATE_CONNECTIONS) \
		-e time_seconds=$(ROTATE_TOTAL_TIME) \
		-e tx_per_second=$(ROTATE_TX_RATE)

.PHONY: restart
restart:
	cd ansible && ansible-playbook -i hosts -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
ifneq ($(VERSION2_WEIGHT), 0)
	cd ansible && ansible-playbook -i hosts --limit validators2 -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG2)" -e "go_modules_token=$(GO_MODULES_TOKEN)"
endif
	cd ansible && ansible-playbook restart-prometheus.yaml -i hosts -u root
	cd ansible && ansible-playbook re-init-testapp.yaml -i hosts -u root -f $(ANSIBLE_FORKS)

.PHONY: rotate
rotate:
	./script/rotate.sh $(VERSION_TAG) `ansible all --list-hosts -i ./ansible/hosts --limit ephemeral | tail +2 | paste -s -d, - | tr -d ' '`

.PHONY: retrieve-blockstore
retrieve-blockstore:
	mkdir -p "./experiments/$(EXPERIMENT_DIR)"
ifeq ($(RETRIEVE_TARGET_HOST), any)
	cd ansible && \
		retrieve_target_host=$$(ansible-inventory -i hosts --host $$(ansible -i hosts --list-hosts validators | tail -1) --yaml | sed 's/^name: //'); \
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

