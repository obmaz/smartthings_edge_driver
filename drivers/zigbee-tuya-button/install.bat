##!/bin/bash
#smartthings edge:channels:create
#smartthings edge:channels:enroll
#smartthings edge:channels:invitations:create
#smartthings edge:drivers:delete
#smartthings edge:drivers:installed
#smartthings edge:drivers:uninstall

smartthings edge:drivers:package ./
smartthings edge:drivers:publish 10c54db8-37d7-4d5b-ac27-e9bf891dbcfd --channel bcdefa83-98fd-42a7-b3c1-dc096200a410
smartthings edge:drivers:install 10c54db8-37d7-4d5b-ac27-e9bf891dbcfd --channel bcdefa83-98fd-42a7-b3c1-dc096200a410 --hub 37d997a3-7579-47f2-8ae9-804fce729f7b
smartthings edge:drivers:logcat --hub-address=192.168.0.119 --all