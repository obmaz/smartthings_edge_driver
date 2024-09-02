# Edge Driver: Zigbee Tuya Button

It is the SmartThings Edge Driver for tuya-platform based zigbee button.  
It supports 1,2,3 and 4 buttons.

## Device

![device](resource/readme-images/device1.jpg)

## App UI Screen

![ui](resource/readme-images/app1.jpg)

## Support Device

See [fingerprints.yml](./fingerprints.yaml)

### Known Issue

#### TS004F

You may need to change the scene mode for it to work.  
Please refer to your device's manual for instructions on how to change it.  

#### TS0601 (EF00 Cluster)

One Click, Hold works, but sometimes the input is ignored.  
Double Click often doesn't work.

## License

It is released under the Apache 2.0 License.