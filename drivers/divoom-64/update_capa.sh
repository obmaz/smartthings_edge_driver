#!/bin/bash
#smartthings edge:drivers:uninstall $driverId --hub $hub
smartthings capabilities:update imageafter45121.channel --input ./resource/capability/channel.yaml
sleep 2
smartthings capabilities:presentation:update imageafter45121.channel 1 --yaml --input=./resource/capability/channel-presentation.yaml
sleep 2

smartthings capabilities:update imageafter45121.weather --input ./resource/capability/weather.yaml
sleep 2
smartthings capabilities:presentation:update imageafter45121.weather 1 --yaml --input=./resource/capability/weather-presentation.yaml
sleep 2

smartthings capabilities:update imageafter45121.message --input ./resource/capability/message.yaml
sleep 2
smartthings capabilities:presentation:update imageafter45121.message 1 --yaml --input=./resource/capability/message-presentation.yaml
sleep 2

smartthings capabilities:update imageafter45121.cloudChannel --input ./resource/capability/cloud-channel.yaml
sleep 2
smartthings capabilities:presentation:update imageafter45121.cloudChannel 1 --yaml --input=./resource/capability/cloud-channel-presentation.yaml
sleep 2

smartthings capabilities:update imageafter45121.customChannel --input ./resource/capability/custom-channel.yaml
sleep 2
smartthings capabilities:presentation:update imageafter45121.customChannel 1 --yaml --input=./resource/capability/custom-channel-presentation.yaml
sleep 2

smartthings capabilities:update imageafter45121.visualizerChannel --input ./resource/capability/visualizer-channel.yaml
sleep 2
smartthings capabilities:presentation:update imageafter45121.visualizerChannel 1 --yaml --input=./resource/capability/visualizer-channel-presentation.yaml
