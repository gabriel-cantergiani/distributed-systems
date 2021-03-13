# BUILD

build-all:
	docker-compose up --build

build-server:
	docker-compose up --build lua-server

build-client:
	docker-compose up --build lua-client

build-client2:
	docker-compose up --build lua-client2

# SSH - Open bash

ssh-server:
	docker-compose run lua-server bash

ssh-client:
	docker-compose run lua-client bash

ssh-client2:
	docker-compose run lua-client2 bash

# RUN
run-server:
	docker-compose up lua-server

run-client:
	docker-compose up lua-client

run-client2:
	docker-compose up lua-client2