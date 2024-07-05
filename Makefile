make: docker-stack.yml
	@echo "Usage: make [deploy|remove|clean]"
	@echo "  deploy: Deploy the stack"
	@echo "  remove: Remove the stack"
	@echo "  clean: Clean up temporary files"

docker-stack.yml:
	@mkdir -p _tmp
	docker stack config -c blackbox-exporter/docker-stack.yml > _tmp/blackbox-exporter.yml
	docker stack config -c cadvisor/docker-stack.yml > _tmp/cadvisor.yml
	docker stack config -c grafana/docker-stack.yml > _tmp/grafana.yml
	docker stack config -c node-exporter/docker-stack.yml > _tmp/node-exporter.yml
	docker stack config -c prometheus/docker-stack.yml > _tmp/prometheus.yml
	docker stack config -c pushgateway/docker-stack.yml > _tmp/pushgateway.yml
	docker stack config \
		--skip-interpolation \
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
	
deploy: docker-stack.yml
	docker stack deploy -c docker-stack.yml promstack

remove:
	docker stack rm promstack

clean:
	@rm -rf _tmp || true
	@rm -f docker-stack.yml || true
