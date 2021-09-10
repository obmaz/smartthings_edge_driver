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
#smartthings edge:channels:delete a9930c26-db95-457c-8fd3-8274a455afb6 

# package : tuya-button
smartthings edge:drivers:uninstall a39fbf59-5d1f-425e-9dd5-a45c57e8c657 --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:package ./
smartthings edge:drivers:publish a39fbf59-5d1f-425e-9dd5-a45c57e8c657 --channel a9930c26-db95-457c-8fd3-8274a455afb6
smartthings edge:drivers:install a39fbf59-5d1f-425e-9dd5-a45c57e8c657 --channel a9930c26-db95-457c-8fd3-8274a455afb6  --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:logcat --hub-address=192.168.0.119 --all