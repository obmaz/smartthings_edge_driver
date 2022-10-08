# SmartThings Edge Driver
It is the SmartThings Edge Drivers.  

## Install
### End-User
You can enroll the channel and install edge drivers by using invitation url   
https://api.smartthings.com/invitation-web/accept?id=2d6da83b-ae22-4fda-8af5-bbb8890872d4

### Developer
The source code required for installation can be found in each directory.  
If necessary, you can manually install it by adding a fingerprinter.  

## Note
### Child Device(DTH) vs Multi Components(Edge Driver)
Unlike the DTH(Device Type Handler), the Edge Driver uses the "Component", not the "Child Device".  
A child device is recognized as a independent thing, while a component shows several buttons in one thing.

The difference is the use of a voice assistant.  
Most voice assistants will be able to recognize only "Main" in Component.  
Therefore, in the case of Button/Swith, the voice assistant may not be able to control the second Button/Switch set as Component.

## License
It is released under the Apache 2.0 License.