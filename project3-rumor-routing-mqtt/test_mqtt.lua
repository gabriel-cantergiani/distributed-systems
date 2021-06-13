local mqtt = require("mqtt_library")

mqtt_client = mqtt.client.create("localhost", 1883, mqttcb)
mqtt_client:connect("cliente love")
mqtt_client:subscribe({"controle"})