#!/bin/bash
#packageKey: 'zigbee-tuya-button'
driverId=95b94182-0102-47ce-acef-553cbd8aa6d6
channel=699fefe6-7b99-40b2-acfd-662ed510a84d
hub=37d997a3-7579-47f2-8ae9-804fce729f7b
hub_address=192.168.0.119

#smartthings edge:drivers:uninstall $driverId --hub $hub
smartthings edge:drivers:package ./
smartthings edge:channels:assign $driverId --channel $channel
smartthings edge:drivers:install $driverId --channel $channel --hub $hub
smartthings edge:drivers:logcat $driverId --hub-address=$hub_address