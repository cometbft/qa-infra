EPHEMERAL_SIZE ?= 0
DO_INSTANCE_TAGNAME=v037-testnet
LOAD_RUNNER_COMMIT_HASH ?= 51685158fe36869ab600527b852437ca0939d0cc
LOAD_RUNNER_CMD=go run github.com/tendermint/tendermint/test/e2e/runner@$(LOAD_RUNNER_COMMIT_HASH)
ANSIBLE_FORKS=20
export DO_INSTANCE_TAGNAME
export EPHEMERAL_SIZE
ROTATE_CONNECTIONS ?= 4
ROTATE_TX_RATE ?= 800
ROTATE_TOTAL_TIME ?= 14400
VERSION_TAG=v0.37.x

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
	echo "[prometheus]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "testnet-observability" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f3   >> ./ansible/hosts
	echo "[loadrunners]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "testnet-load" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f3   >> ./ansible/hosts
	echo "[ephemeral]" >> ./ansible/hosts
	doctl compute droplet list --tag-name "ephemeral-node" | tail -n+2 | grep $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' >> ./ansible/hosts

.PHONY: configgen
configgen:
	./script/configgen.sh $(VERSION_TAG) `ansible -i ./ansible/hosts --list-hosts validators | tail +2 | sed  's/ //g' | paste -s -d, -` \
		`grep seed ./ansible/hosts | cut -d' ' -f1| paste -s -d, -`

.PHONY: ansible-install
ansible-install:
	cd ansible && \
		ansible-playbook -i hosts -u root base.yaml -f $(ANSIBLE_FORKS) && \
		ansible-playbook -i hosts -u root prometheus-node-exporter.yaml -f $(ANSIBLE_FORKS) && \
		ansible-playbook -i hosts -u root init-testapp.yaml -f $(ANSIBLE_FORKS) && \
		ansible-playbook -i hosts -u root update-testapp.yaml -f $(ANSIBLE_FORKS) -e "version_tag=$(VERSION_TAG)"

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
	cd ansible &&  ansible-playbook runload.yaml -i hosts -u root -e endpoints=`ansible -i ./hosts --list-hosts validators | tail +2 | sed  "s/ //g" | sed 's/\(.*\)/ws:\/\/\1:26657\/websocket/' | paste -s -d, -`

.PHONY: runload-rotate
runload-rotate:
	cd ansible &&  ansible-playbook runload.yaml -i hosts -u root \
		-e endpoints=`ansible -i ./hosts --list-hosts validators | tail +2 | tail -1 | sed  "s/ //g" | sed 's/\(.*\)/ws:\/\/\1:26657\/websocket/' | paste -s -d, -` \
		-e connections=$(ROTATE_CONNECTIONS) \
		-e time_seconds=$(ROTATE_TOTAL_TIME) \
		-e tx_per_second=$(ROTATE_TX_RATE)

.PHONY: restart
restart:
	cd ansible &&  ansible-playbook restart-prometheus.yaml -i hosts -u root
	cd ansible &&  ansible-playbook re-init-testapp.yaml -i hosts -u root -f $(ANSIBLE_FORKS)

.PHONY: rotate
rotate:
	./script/rotate.sh $(VERSION_TAG) `ansible all --list-hosts -i ./ansible/hosts --limit ephemeral | tail +2 | paste -s -d, - | tr -d ' '`

retrieve-data:
	@DIR=`date "+%Y-%m-%d-%H_%M_%S%N"`; \
	mkdir -p "./experiments/$${DIR}"; \
	cd ansible && ansible-playbook -i hosts -u root retrieve-blockstore.yaml -e "dir=../experiments/$${DIR}/"; \
	ansible-playbook -i hosts -u root retrieve-prometheus.yaml --limit `ansible -i hosts --list-hosts prometheus | tail -1 | sed  's/ //g'` -e "dir=../experiments/$${DIR}/";

.PHONY: terraform-destroy
terraform-destroy:
	$(MAKE) -C ./tf/ destroy

