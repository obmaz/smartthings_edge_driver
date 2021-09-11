##!/bin/bash
#smartthings edge:channels:create
#smartthings edge:channels:enroll
#smartthings edge:channels:drivers
#smartthings edge:channels:invitations:create
#smartthings edge:drivers:delete
#smartthings edge:drivers:installed
#smartthings edge:drivers:uninstall

#smartthings edge:channels:delete 15b67bc8-e6ae-4856-a72d-c4ef00815db0 

# package : zigbee-tuya-switch
smartthings edge:drivers:uninstall  c6e91dbe-ae2c-4dc2-bce1-a3e553aff9e4 --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:package ./
smartthings edge:drivers:publish c6e91dbe-ae2c-4dc2-bce1-a3e553aff9e4 --channel 15b67bc8-e6ae-4856-a72d-c4ef00815db0
smartthings edge:drivers:install c6e91dbe-ae2c-4dc2-bce1-a3e553aff9e4 --channel 15b67bc8-e6ae-4856-a72d-c4ef00815db0  --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:logcat --hub-address=192.168.0.119 --all