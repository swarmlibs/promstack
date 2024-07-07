DOCKER_STACK_CONFIG := docker stack config
DOCKER_STACK_CONFIG_ARGS := --skip-interpolation

# if darwin == true, then use the cadvisor_docker_stack_darwin.yml file
macos := false
cadvisor_docker_stack_file := cadvisor/docker-stack.yml
ifeq ($(macos),true)
	cadvisor_docker_stack_file := cadvisor/docker-stack-macos.yml
endif

make: docker-stack.yml
	@echo "Usage: make [deploy|remove|clean]"
	@echo "  deploy: Deploy the stack"
	@echo "  remove: Remove the stack"
	@echo "  clean: Clean up temporary files"

docker-stack.yml:
	@mkdir -p _tmp
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) -c blackbox-exporter/docker-stack.yml > _tmp/blackbox-exporter.yml
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) -c $(cadvisor_docker_stack_file) > _tmp/cadvisor.yml
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) -c grafana/docker-stack.yml > _tmp/grafana.yml
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) -c node-exporter/docker-stack.yml > _tmp/node-exporter.yml
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) -c prometheus/docker-stack.yml > _tmp/prometheus.yml
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) -c pushgateway/docker-stack.yml > _tmp/pushgateway.yml
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) \
		-c _tmp/blackbox-exporter.yml \
		-c _tmp/cadvisor.yml \
		-c _tmp/grafana.yml \
		-c _tmp/node-exporter.yml \
		-c _tmp/prometheus.yml \
		-c _tmp/pushgateway.yml \
	> docker-stack.yml
	@rm -rf _tmp
	@sed "s|$(PWD)/||g" docker-stack.yml > docker-stack.yml.tmp
	@rm docker-stack.yml
	@mv docker-stack.yml.tmp docker-stack.yml
	
deploy: docker-stack.yml stack-deploy
remove: stack-remove config-prune

clean:
	@rm -rf _tmp || true
	@rm -f docker-stack.yml || true

stack-deploy:
	docker stack deploy -c docker-stack.yml promstack
stack-remove:
	docker stack rm promstack
config-prune:
	docker config ls -q | xargs docker config rm
volume-prune:
	docker volume ls -q | xargs docker volume rm
