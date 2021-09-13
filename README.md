# Smartthings Edge Driver
It is the SmartThings Edge Drivers.  

## Invitation URL
https://api.smartthings.com/invitation-web/accept?id=360bee66-61e0-47cd-8bc0-67a0ed3aadf6  

## Uploading Driver to SmartThings

See : https://community.smartthings.com/t/tutorial-creating-drivers-for-zigbee-devices-with-smartthings-edge/229502

## Note
Unlike the DTH(Device Type Handler), the Edge Driver uses the "Component", not the "Child Device".  
A child device is recognized as a independent thing, while a component shows several buttons in one thing.

The difference is the use of a voice assistant.  
Most voice assistants will be able to recognize only "Main" in Component.  
Therefore, in the case of Button/Swith, the voice assistant may not be able to control the second Button/Switch set as Component.

## License
It is released under the Apache 2.0 License.