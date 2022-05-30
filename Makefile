DO_INSTANCE_TAGNAME=v036-testnet
TESTNET_SIZE=20

hosts:
	echo "[validators]" > ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) | head | tr -s ' ' | cut -d' ' -f3 | tail -n+2 >> ./ansible/hosts

configgen:
	./script/configgen.sh $(TESTNET_SIZE)

