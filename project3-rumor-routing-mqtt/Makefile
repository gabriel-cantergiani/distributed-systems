# RUN ON DOCKER CONTAINER
run-mosquitto-server:
	docker-compose up -d mosquitto-server

run-client-container:
	docker-compose up lua-client

run-love:
	"C:\Program Files\LOVE\love.exe" . 1

run-all: run-mosquitto-server run-love

# RUN LOCAL
run-server:
	lua server.lua

run-client:
	lua client.lua localhost 8888