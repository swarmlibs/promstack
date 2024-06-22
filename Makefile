docker-stack-name = test_prometheus

it:
	@echo "make [deploy|remove|clean|reset] docker-stack-name=$(docker-stack-name)"

networks:
	@docker network create --scope=swarm --driver=overlay --attachable dockerswarm_ingress > /dev/null 2>&1 || true
	@docker network create --scope=swarm --driver=overlay --attachable dockerswarm_metrics > /dev/null 2>&1 || true
	@docker network create --scope=swarm --driver=overlay --attachable prometheus_exporters > /dev/null 2>&1 || true

deploy: networks
	$(MAKE) -C prometheus deploy
	$(MAKE) -C alertmanager deploy
	$(MAKE) -C cadvisor deploy
	$(MAKE) -C node-exporter deploy

remove:
	$(MAKE) -C prometheus remove
	$(MAKE) -C alertmanager remove
	$(MAKE) -C cadvisor remove
	$(MAKE) -C node-exporter remove

clean:
	$(MAKE) -C prometheus clean
	$(MAKE) -C alertmanager clean
	$(MAKE) -C cadvisor clean
	$(MAKE) -C node-exporter clean

reset: remove clean deploy
