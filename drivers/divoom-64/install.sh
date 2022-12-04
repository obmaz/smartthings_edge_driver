#!/bin/bash
driverId=598332a7-775e-45cc-bb9c-246bff3041a1
channel=699fefe6-7b99-40b2-acfd-662ed510a84d
hub=37d997a3-7579-47f2-8ae9-804fce729f7b
hub_address=192.168.0.119

#smartthings edge:drivers:uninstall $driverId --hub $hub
smartthings capabilities:update imageafter45121.channel --input ./resource/capability/channel.yaml
smartthings capabilities:presentation:update imageafter45121.channel 1 --yaml --input=./resource/capability/channel-presentation.yaml

smartthings capabilities:update imageafter45121.weather --input ./resource/capability/weather.yaml
smartthings capabilities:presentation:update imageafter45121.weather 1 --yaml --input=./resource/capability/weather-presentation.yaml

smartthings capabilities:update imageafter45121.message --input ./resource/capability/message.yaml
smartthings capabilities:presentation:update imageafter45121.message 1 --yaml --input=./resource/capability/message-presentation.yaml

smartthings capabilities:update imageafter45121.cloudChannel --input ./resource/capability/cloud-channel.yaml
smartthings capabilities:presentation:update imageafter45121.cloudChannel 1 --yaml --input=./resource/capability/cloud-channel-presentation.yaml

smartthings capabilities:update imageafter45121.customChannel --input ./resource/capability/custom-channel.yaml
smartthings capabilities:presentation:update imageafter45121.customChannel 1 --yaml --input=./resource/capability/custom-channel-presentation.yaml

smartthings capabilities:update imageafter45121.visualizerChannel --input ./resource/capability/visualizer-channel.yaml
smartthings capabilities:presentation:update imageafter45121.visualizerChannel 1 --yaml --input=./resource/capability/visualizer-channel-presentation.yaml

vid=`smartthings presentation:device-config:create --yaml --input ./resource/device-config/lan-divoom-device-config.yaml | grep vid`
sed -e "s/vid.*/$vid/g" ./profiles/lan-divoom.yaml | sponge ./profiles/lan-divoom.yaml
smartthings edge:drivers:package ./
smartthings edge:channels:assign $driverId --channel $channel
smartthings edge:drivers:install $driverId --channel $channel --hub $hub
smartthings edge:drivers:logcat $driverId --hub-address=$hub_address