# SmartThings Edge Driver
It is the SmartThings Edge Drivers.  
See the readme in each directory for detail

See Another Edge Repo: [Samsung Air-condition af-ha153](https://github.com/obmaz/samsung_aircon_connector)

## Install
### End-User
You can enroll the channel and install edge drivers by using invitation url   
https://api.smartthings.com/invitation-web/accept?id=2d6da83b-ae22-4fda-8af5-bbb8890872d4

### Developer
The source code required for installation can be found in each directory.  
If necessary, you can manually install it by adding a fingerprint.  

## Note
### Child Device(DTH) vs Multi Components(Edge Driver)
**Update:** The latest edge driver supports child devices, but this driver uses a multi-component method.

Unlike the DTH (Device Type Handler), the Edge Driver uses “Components” instead of “Child Devices.”
A Child Device is treated as a separate device, whereas a Component allows multiple buttons to appear within a single device.

One key difference is how voice assistants handle them.
Most voice assistants recognize only the Main component.
As a result, if a Button or Switch is set as a Component, the voice assistant may not be able to control the second one.

## License
It is released under the Apache 2.0 License.

<a href="https://www.buymeacoffee.com/zambobmaz" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
