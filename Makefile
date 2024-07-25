DOCKER_STACK_CONFIG := docker stack config
DOCKER_STACK_CONFIG_ARGS := --skip-interpolation

.EXPORT_ALL_VARIABLES:
include .dockerenv

make:
	@echo "Usage: make [deploy|remove|clean]"
	@echo "  deploy: Deploy the stack"
	@echo "  remove: Remove the stack"
	@echo "  clean: Clean up temporary files"


define docker-stack-config
cd $1 \
&& $(DOCKER_STACK_CONFIG) -c docker-stack.tmpl.yml > docker-stack-config.yml \
&& sed "s|$(PWD)/$1/|./|g" docker-stack-config.yml > docker-stack.yml
endef

compile: docker-stack.yml
docker-stack.yml:
	$(call docker-stack-config,blackbox-exporter)
	$(call docker-stack-config,cadvisor)
	$(call docker-stack-config,grafana)
	$(call docker-stack-config,node-exporter)
	$(call docker-stack-config,prometheus)
	$(call docker-stack-config,pushgateway)
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) \
		-c blackbox-exporter/docker-stack-config.yml \
		-c cadvisor/docker-stack-config.yml \
		-c grafana/docker-stack-config.yml \
		-c node-exporter/docker-stack-config.yml \
		-c prometheus/docker-stack-config.yml \
		-c pushgateway/docker-stack-config.yml \
	> docker-stack.yml.tmp
	@sed "s|$(PWD)/||g" docker-stack.yml.tmp > docker-stack.yml
	@rm docker-stack.yml.tmp
	@rm **/docker-stack-config.yml

print:
	$(DOCKER_STACK_CONFIG) -c docker-stack.yml

clean:
	@rm -rf _tmp || true
	@rm -f docker-stack.yml || true

deploy: compile stack-deploy
remove: stack-remove

stack-deploy:
	docker network create --scope=swarm --driver=overlay --attachable public || true
	docker network create --scope=swarm --driver=overlay --attachable prometheus || true
	docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork || true
	docker stack deploy --detach --prune -c docker-stack.yml promstack
stack-remove:
	docker stack rm promstack
