docker-image := trnubo/monitor

help:
	@echo -e "Helper for common tasks\n\n\
	build:	build docker image\n"

build:
	docker build -t $(docker-image) .

bash:
	docker run --rm -it --link sensu:sensu --hostname $(HOSTNAME) $(docker-image) bash; echo $?

run:
	docker run --rm -it --link sensu:sensu -v /:/host:ro $(docker-image)

exec:
	docker exec -it $(shell docker ps | grep $(docker-image) | awk '{print $$1}') bash