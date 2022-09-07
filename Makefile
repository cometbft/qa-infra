DO_INSTANCE_TAGNAME=v037-testnet
LOAD_RUNNER_COMMIT_HASH ?= 51685158fe36869ab600527b852437ca0939d0cc
LOAD_RUNNER_CMD=go run github.com/tendermint/tendermint/test/e2e/runner@$(LOAD_RUNNER_COMMIT_HASH)
export DO_INSTANCE_TAGNAME
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
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) --tag-name "testnet-node" | tail -n+2 |  tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' >> ./ansible/hosts
	echo "[prometheus]" >> ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) --tag-name "testnet-observability" | tail -n+2 |  tr -s ' ' | cut -d' ' -f3   >> ./ansible/hosts

.PHONY: configgen
configgen:
	./script/configgen.sh $(VERSION_TAG) `grep ' name=' ./ansible/hosts | cut -d' ' -f1 | paste -s -d, -`

.PHONY: ansible-install
ansible-install:
	cd ansible && \
		ansible-playbook -i hosts -u root base.yaml -f 10 && \
		ansible-playbook -i hosts -u root prometheus-node-exporter.yaml -f 10 && \
		ansible-playbook -i hosts -u root init-testapp.yaml -f 10 && \
		ansible-playbook -i hosts -u root update-testapp.yaml -f 10 -e "version_tag=$(VERSION_TAG)"

.PHONY: prometheus-init
prometheus-init:
	cd ansible && ansible-playbook -i hosts  -u root prometheus.yaml -f 10

.PHONY: start-network
start-network:
	cd ansible && ansible-playbook -i hosts -u root start-testapp.yaml -f 10

.PHONY: runload
runload:
	$(LOAD_RUNNER_CMD) load \
		--ip-list `grep ' name=' ./ansible/hosts | cut -d' ' -f1 | paste -s -d, -` \
		--seed-delta $(shell echo $$RANDOM)

retrieve-data:
	@DIR=`date "+%Y-%m-%d-%H_%M_%S%N"`; \
	mkdir -p "./experiments/$${DIR}"; \
	cd ansible && ansible-playbook -i hosts -u root retrieve-blockstore.yaml --limit `ansible -i hosts --list-hosts validators | tail -1| sed  's/ //g'` -e "dir=../experiments/$${DIR}/blockstore.db.zip"; \
	ansible-playbook -i hosts -u root retrieve-prometheus.yaml --limit `ansible -i hosts --list-hosts prometheus | tail -1| sed  's/ //g'` -e "dir=../experiments/$${DIR}/prometheus.zip"; \
	cd "../experiments/$${DIR}/" && unzip "blockstore.db.zip"; \
	unzip "prometheus.zip"

.PHONY: terraform-destroy
terraform-destroy:
	$(MAKE) -C ./tf/ destroy

