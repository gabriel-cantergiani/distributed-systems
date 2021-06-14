# RUN ON DOCKER CONTAINER
run-mosquitto-server:
	docker-compose up -d mosquitto-server

run-client-container:
	docker-compose up lua-client

# env:Path += ";C:\Program Files\LOVE\"
run-love:
	powershell.exe "love.exe . 1"
	powershell.exe "love.exe . 2"
	powershell.exe "love.exe . 3"
	powershell.exe "love.exe . 4"
# powershell.exe "love.exe . 5"
# powershell.exe "love.exe . 6"
# powershell.exe "love.exe . 7"
# powershell.exe "love.exe . 8"
# powershell.exe "love.exe . 9"
# powershell.exe "love.exe . 10"
# powershell.exe "love.exe . 11"
# powershell.exe "love.exe . 12"
# powershell.exe "love.exe . 13"
# powershell.exe "love.exe . 14"
# powershell.exe "love.exe . 15"
# powershell.exe "love.exe . 16"

run-all: run-mosquitto-server run-love

# RUN LOCAL
run-server:
	lua server.lua

run-client:
	lua client.lua localhost 8888