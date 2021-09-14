#!/bin/bash
@REM # CLI Commands
@REM # smartthings edge:channels:create
@REM # smartthings edge:channels:enroll %hub%
@REM # smartthings edge:channels:unenroll %hub%
@REM # smartthings edge:channels:enrollments %hub%
@REM # smartthings edge:channels:drivers %channel%
@REM # smartthings edge:channels:delete %channel%
@REM # smartthings edge:channels:invitations:create
@REM # smartthings edge:channels:invitations:delete
@REM # smartthings edge:drivers:delete
@REM # smartthings edge:drivers:installed --hub %hub%
@REM # smartthings edge:drivers:uninstall --hub %hub%

@REM # For window : zigbee-tuya-switch-temp
set driverId=c6e91dbe-ae2c-4dc2-bce1-a3e553aff9e4
set channel=f86b30bb-00d0-4b90-8849-53beb1109dba
set hub=37d997a3-7579-47f2-8ae9-804fce729f7b
set hub_address=192.168.0.119

@REM # For Posix : zigbee-tuya-switch-temp
driverId=c6e91dbe-ae2c-4dc2-bce1-a3e553aff9e4
channel=f86b30bb-00d0-4b90-8849-53beb1109dba
hub=37d997a3-7579-47f2-8ae9-804fce729f7b
hub_address=192.168.0.119

@REM # Each OS will show error like "command not found", but it's ok
smartthings edge:drivers:uninstall %driverId% --hub %hub%
smartthings edge:drivers:package ./
smartthings edge:drivers:publish %driverId% --channel %channel%
smartthings edge:drivers:install %driverId% --channel %channel% --hub %hub%
smartthings edge:drivers:logcat --hub-address=%hub_address% --all

smartthings edge:drivers:uninstall $driverId --hub $hub
smartthings edge:drivers:package ./
smartthings edge:drivers:publish $driverId --channel $channel
smartthings edge:drivers:install $driverId --channel $channel --hub $hub
smartthings edge:drivers:logcat --hub-address=$hub_address --all