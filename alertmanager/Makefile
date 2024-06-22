docker-stack-name = promstack_alertmanager

it:
	@echo "make [deploy|remove|clean|reset] docker-stack-name=$(docker-stack-name)"

deploy:
	docker stack deploy -c docker-stack.yml $(docker-stack-name)

remove:
	docker stack rm --detach=false $(docker-stack-name)

clean:
	docker volume ls -q | grep $(docker-stack-name) | xargs docker volume rm

reset: remove wait clean deploy

wait:
	@echo "Waiting for previous recipe to finish..."
	@sleep 10
