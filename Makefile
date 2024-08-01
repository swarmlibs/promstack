DOCKER_STACK_NAMESPACE := promstack
DOCKER_STACK_CONFIG := docker stack config
DOCKER_STACK_CONFIG_ARGS := --skip-interpolation
DOCKER_STACK_DEPLOY := docker stack deploy
DOCKER_STACK_DEPLOY_ARGS := --detach --with-registry-auth

.EXPORT_ALL_VARIABLES:
include .dockerenv
-include .env

make:
	@echo "Usage: make [deploy|remove|clean]"
	@echo "  deploy: Deploy the stack"
	@echo "  remove: Remove the stack"
	@echo "  clean: Clean up temporary files"

define docker-stack-config
$(1)/compile: $(1)/docker-stack.yml
$(1)/config:
	cat $(1)/docker-stack.yml
$(1)/docker-stack.yml:
	$(DOCKER_STACK_CONFIG) -c $1/docker-stack.tmpl.yml > $1/docker-stack-config.yml
	@sed "s|$(PWD)/$1/|./|g" $1/docker-stack-config.yml > $1/docker-stack.yml
$(1)/deploy:
	$(DOCKER_STACK_DEPLOY) $(DOCKER_STACK_DEPLOY_ARGS) -c $(1)/docker-stack.yml $(DOCKER_STACK_NAMESPACE)
$(1)/upgrade: $(1)/clean $(1)/compile
	$(DOCKER_STACK_DEPLOY) $(DOCKER_STACK_DEPLOY_ARGS) --resolve-image always -c $(1)/docker-stack.yml $(DOCKER_STACK_NAMESPACE)
$(1)/remove:
	yq '.services[]|key' $(1)/docker-stack.yml | xargs -I {} docker service rm $(DOCKER_STACK_NAMESPACE)_{}
$(1)/clean:
	@rm -rf $(1)/docker-stack.yml || true
	@rm -rf $(1)/docker-stack-config.yml || true
endef

$(eval $(call docker-stack-config,blackbox-exporter))
$(eval $(call docker-stack-config,cadvisor))
$(eval $(call docker-stack-config,grafana))
$(eval $(call docker-stack-config,node-exporter))
$(eval $(call docker-stack-config,prometheus))
$(eval $(call docker-stack-config,pushgateway))

docker-stack.yml:
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) \
		-c blackbox-exporter/docker-stack-config.yml \
		-c cadvisor/docker-stack-config.yml \
		-c grafana/docker-stack-config.yml \
		-c node-exporter/docker-stack-config.yml \
		-c prometheus/docker-stack-config.yml \
		-c pushgateway/docker-stack-config.yml \
	> docker-stack.yml.tmp
	@sed "s|$(PWD)/|./|g" docker-stack.yml.tmp > docker-stack.yml
	@rm docker-stack.yml.tmp
	@rm **/docker-stack-config.yml

compile: \
	blackbox-exporter/docker-stack.yml \
	cadvisor/docker-stack.yml \
	grafana/docker-stack.yml \
	node-exporter/docker-stack.yml \
	prometheus/docker-stack.yml \
	pushgateway/docker-stack.yml \
	docker-stack.yml

print:
	$(DOCKER_STACK_CONFIG) -c docker-stack.yml

clean:
	@rm -rf docker-stack.yml || true
	@rm -rf docker-stack.yml.tmp || true
	@rm -rf **/docker-stack.yml || true
	@rm -rf **/docker-stack-config.yml || true

deploy: compile stack-networks stack-deploy
upgrade: clean compile stack-upgrade
remove: stack-remove

stack-networks:
	docker network create --scope=swarm --driver=overlay --attachable public || true
	docker network create --scope=swarm --driver=overlay --attachable prometheus || true
	docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork || true
stack-deploy:
	$(DOCKER_STACK_DEPLOY) $(DOCKER_STACK_DEPLOY_ARGS) --prune -c docker-stack.yml $(DOCKER_STACK_NAMESPACE)
stack-upgrade:
	$(DOCKER_STACK_DEPLOY) $(DOCKER_STACK_DEPLOY_ARGS) --prune --resolve-image always -c docker-stack.yml $(DOCKER_STACK_NAMESPACE)
stack-remove:
	docker stack rm $(DOCKER_STACK_NAMESPACE)
