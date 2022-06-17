@REM # CLI Commands
@REM smartthings edge:channels:assign
@REM smartthings edge:channels:create
@REM smartthings edge:channels:delete %channel%
@REM smartthings edge:channels:drivers %channel%
@REM smartthings edge:channels:enroll %hub%
@REM smartthings edge:channels:enrollments %hub%
@REM smartthings edge:channels:unassign --channel %channel%
@REM smartthings edge:channels:unenroll %hub%
@REM smartthings edge:channels:update
@REM smartthings edge:channels:invitations:create
@REM smartthings edge:channels:invitations:delete
@REM smartthings edge:drivers:delete
@REM smartthings edge:drivers:install %driverId% --channel %channel% --hub %hub%
@REM smartthings edge:drivers:installed --hub %hub%
@REM smartthings edge:drivers:logcat --hub-address=%hub_address% --all
@REM smartthings edge:drivers:package ./
@REM smartthings edge:drivers:uninstall --hub %hub%

@REM packageKey: 'zigbee-aqara-button'
set driverId=e8f777f7-283f-4fa6-aabc-933d53e54a3b
set channel=699fefe6-7b99-40b2-acfd-662ed510a84d
set hub=37d997a3-7579-47f2-8ae9-804fce729f7b
set hub_address=192.168.0.119

@REM smartthings edge:drivers:uninstall %driverId% --hub %hub%
smartthings edge:drivers:package ./
smartthings edge:drivers:publish %driverId% --channel %channel%
smartthings edge:drivers:install %driverId% --channel %channel% --hub %hub%
smartthings edge:drivers:logcat %driverId% --hub-address=%hub_address%