#!/bin/bash
driverId=598332a7-775e-45cc-bb9c-246bff3041a1
channel=699fefe6-7b99-40b2-acfd-662ed510a84d
hub=37d997a3-7579-47f2-8ae9-804fce729f7b
hub_address=192.168.0.119

#smartthings edge:drivers:uninstall $driverId --hub $hub
smartthings capabilities:presentation:update imageafter45121.divoomChannel 1 --yaml --input=./resource/presentation/divoom-channel-presentation.yaml
smartthings presentation:device-config:create --yaml --input ./resource/device-config/lan-divoom-device-config.yaml | sponge ./resource/device-config/lan-divoom-device-config.yaml
srcVid=`cat ./resource/device-config/lan-divoom-device-config.yaml | grep presentationId | awk '{print $2}'`
tarVid=`cat ./profiles/lan-divoom.yaml | grep vid | awk '{print $2}'`
sed -e "s/$tarVid/$srcVid/g" ./profiles/lan-divoom.yaml | sponge ./profiles/lan-divoom.yaml
smartthings edge:drivers:package ./
smartthings edge:channels:assign $driverId --channel $channel
smartthings edge:drivers:install $driverId --channel $channel --hub $hub
smartthings edge:drivers:logcat $driverId --hub-address=$hub_address