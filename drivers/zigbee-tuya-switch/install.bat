#!/bin/bash
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


@REM packageKey: 'zigbee-tuya-switch'
@REM set driverId=de2773fd-2901-4254-9009-276f1ca90350

@REM packageKey: 'zigbee-tuya-switch-dev'
set driverId=ac07f7e5-09a3-4899-9fb4-5f9cf0589488

set channel=699fefe6-7b99-40b2-acfd-662ed510a84d
set hub=37d997a3-7579-47f2-8ae9-804fce729f7b
set hub_address=192.168.0.119

@REM # Each OS will show error like "command not found", but it's ok
smartthings edge:drivers:uninstall %driverId% --hub %hub%
smartthings edge:drivers:package ./
smartthings edge:drivers:publish %driverId% --channel %channel%
smartthings edge:drivers:install %driverId% --channel %channel% --hub %hub%
smartthings edge:drivers:logcat -all --hub-address=%hub_address%

@REM # For Posix : zigbee-tuya-switch
@REM driverId=de2773fd-2901-4254-9009-276f1ca90350
@REM channel=f86b30bb-00d0-4b90-8849-53beb1109dba
@REM hub=37d997a3-7579-47f2-8ae9-804fce729f7b
@REM hub_address=192.168.0.119

@REM smartthings edge:drivers:uninstall $driverId --hub $hub
@REM smartthings edge:drivers:package ./
@REM smartthings edge:drivers:publish $driverId --channel $channel
@REM smartthings edge:drivers:install $driverId --channel $channel --hub $hub
@REM smartthings edge:drivers:logcat --hub-address=$hub_address --all