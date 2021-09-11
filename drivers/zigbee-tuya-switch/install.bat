##!/bin/bash
#smartthings edge:channels:create
#smartthings edge:channels:enroll
#smartthings edge:channels:drivers
#smartthings edge:channels:invitations:create
#smartthings edge:drivers:delete
#smartthings edge:drivers:installed
#smartthings edge:drivers:uninstall

# package : zigbee-tuya-switch
smartthings edge:drivers:uninstall 86d0e12f-c446-47b9-9302-8436d4a53d20 --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:package ./
smartthings edge:drivers:publish 86d0e12f-c446-47b9-9302-8436d4a53d20 --channel 2ec883d2-a3ad-43d6-b664-a86844516ac5
smartthings edge:drivers:install 86d0e12f-c446-47b9-9302-8436d4a53d20 --channel 2ec883d2-a3ad-43d6-b664-a86844516ac5  --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:logcat --hub-address=192.168.0.119 --all