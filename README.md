# SmartThings Edge Driver
These are the SmartThings Edge Drivers.  
See the README in each directory for details.

See Another Edge Repo: [Samsung Air-condition af-ha153](https://github.com/obmaz/samsung_aircon_connector)

## Install
### End-User
You can enroll in the channel and install Edge Drivers using the invitation URL.  
https://api.smartthings.com/invitation-web/accept?id=2d6da83b-ae22-4fda-8af5-bbb8890872d4

### Developer
The source code required for installation is located in each directory.  
If necessary, you can manually install it by adding a fingerprint.

## Note
### Child Device(DTH) vs Multi Components(Edge Driver)
**Update:** The latest Edge Driver supports Child Devices, but this driver uses a multi-component approach.  

Unlike a DTH (Device Type Handler), the Edge Driver uses “Components” instead of “Child Devices.”  
A Child Device is treated as a separate device, whereas a Component allows multiple buttons to be included within a single device.  

One key difference is how voice assistants handle them.  
Most voice assistants recognize only the Main component.  
As a result, if a Button or Switch is set as a Component, the voice assistant may not be able to control additional components.

## License
It is released under the Apache License 2.0.

<a href="https://www.buymeacoffee.com/zambobmaz" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
