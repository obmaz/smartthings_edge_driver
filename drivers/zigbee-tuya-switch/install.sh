#!/bin/bash
#packageKey: 'zigbee-tuya-button'
driverId=de2773fd-2901-4254-9009-276f1ca90350
channel=699fefe6-7b99-40b2-acfd-662ed510a84d
hub=37d997a3-7579-47f2-8ae9-804fce729f7b
hub_address=192.168.10.205

#smartthings edge:drivers:uninstall $driverId --hub $hub
smartthings edge:drivers:package ./
smartthings edge:channels:assign $driverId --channel $channel
smartthings edge:drivers:install $driverId --channel $channel --hub $hub
smartthings edge:drivers:logcat $driverId --hub-address=$hub_address