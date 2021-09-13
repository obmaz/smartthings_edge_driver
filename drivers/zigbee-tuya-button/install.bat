# CLI Commands
# smartthings edge:channels:create
# smartthings edge:channels:enroll
# smartthings edge:channels:drivers %channel%
# smartthings edge:channels:delete %channel%
# smartthings edge:channels:invitations:create
# smartthings edge:drivers:delete
# smartthings edge:drivers:installed
# smartthings edge:drivers:uninstall

$driverId=d915dd32-c84d-4a0b-8ed1-3443be2b8479
$channel=15b67bc8-e6ae-4856-a72d-c4ef00815db0
$hub=37d997a3-7579-47f2-8ae9-804fce729f7b
$hub-address=192.168.0.119

# package : tuya-button
smartthings edge:drivers:uninstall %driverId% --hub %hub%
smartthings edge:drivers:package ./
smartthings edge:drivers:publish %driverId% --channel %channel%
smartthings edge:drivers:install %driverId% --channel %channel% --hub %hub%
smartthings edge:drivers:logcat --hub-address=%hub-address% --all