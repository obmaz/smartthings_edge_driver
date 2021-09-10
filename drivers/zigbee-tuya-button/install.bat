##!/bin/bash
#smartthings edge:channels:create
#smartthings edge:channels:enroll
#smartthings edge:channels:drivers
#smartthings edge:channels:invitations:create
#smartthings edge:drivers:delete
#smartthings edge:drivers:installed
#smartthings edge:drivers:uninstall

# package : zigbee-tuya-button 유령 채널에 존재해서 꼬임 (bcdefa83-98fd-42a7-b3c1-dc096200a410)
# 채널과 드라이버가 지워지지 않음
#smartthings edge:drivers:delete 10c54db8-37d7-4d5b-ac27-e9bf891dbcfd
#smartthings edge:channels:delete 2ec883d2-a3ad-43d6-b664-a86844516ac5 

# package : tuya-button
smartthings edge:drivers:uninstall d915dd32-c84d-4a0b-8ed1-3443be2b8479 --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:package ./
smartthings edge:drivers:publish d915dd32-c84d-4a0b-8ed1-3443be2b8479 --channel 2ec883d2-a3ad-43d6-b664-a86844516ac5
smartthings edge:drivers:install d915dd32-c84d-4a0b-8ed1-3443be2b8479 --channel 2ec883d2-a3ad-43d6-b664-a86844516ac5  --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:logcat --hub-address=192.168.0.119 --all