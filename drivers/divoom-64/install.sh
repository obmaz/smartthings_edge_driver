#!/bin/bash
driverId=598332a7-775e-45cc-bb9c-246bff3041a1
channel=699fefe6-7b99-40b2-acfd-662ed510a84d
hub=b5434d2c-cd4e-4bde-a91b-d419ee72c55e
hub_address=192.168.10.189

vid=$(smartthings presentation:device-config:create --yaml --input ./resource/device-config/lan-divoom-device-config.yaml | grep vid)
sed -e "s/vid.*/$vid/g" ./profiles/lan-divoom.yaml | sponge ./profiles/lan-divoom.yaml

smartthings edge:drivers:package ./
smartthings edge:channels:assign $driverId --channel $channel
smartthings edge:drivers:install $driverId --channel $channel --hub $hub
smartthings edge:drivers:logcat $driverId --hub-address=$hub_address