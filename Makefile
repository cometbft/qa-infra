DO_INSTANCE_TAGNAME=v035-testnet
LOAD_RUNNER_COMMIT_HASH ?= 51685158fe36869ab600527b852437ca0939d0cc
LOAD_RUNNER_CMD=go run github.com/tendermint/tendermint/test/e2e/runner@$(LOAD_RUNNER_COMMIT_HASH)
E2E_RUNNER_VERSION=v0.35.5
export DO_INSTANCE_TAGNAME
export LOAD_RUNNER_CMD
export E2E_RUNNER_VERSION

.PHONY: init
init:
	$(MAKE) -C ./tf/ init

.PHONY: deploy
deploy:
	$(MAKE) -C ./tf/ apply
	./script/configgen.sh ./ansible/hosts
	./script/secretsgen.sh ./ansible/secrets.yaml
	ANSIBLE_HOST_KEY_CHECKING=False \
		ansible-playbook -i ./ansible/hosts -u root ./ansible/deploy.yaml -f 10

.PHONY: update-testapp
update-testapp:
	./script/configgen.sh ./ansible/hosts
	ANSIBLE_HOST_KEY_CHECKING=False \
		ansible-playbook -i ./ansible/hosts -u root ./ansible/update-testapp.yaml

.PHONY: runload
runload:
	./script/runload.sh ./ansible/hosts

.PHONY: destroy
destroy:
	$(MAKE) -C ./tf/ destroy

