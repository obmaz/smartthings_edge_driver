#!/bin/bash
######################################################################################
# Generate / Post Device Configuration
# It makes the deviceConfig.yaml based on dth. The dth uid can be found on groovy ide url
# $smartthings presentation:device-config:generate f1f4018d-696d-451d-b84f-1cee0cc267b5 --dth --output=deviceConfig.yaml --yaml
######################################################################################
# Create VID
# it makes the vid based on deviceConfig.yaml
# $smartthings presentation:device-config:create --yaml --input deviceConfig.yaml
#
# It will show vid and mnmn. Please keeps vid and mnmn
#    "vid": "1508c046-1429-3642-b115-a805a64ec459",
#    "mnmn": "SmartThingsCommunity",
#
# if vid is the same as previous (it happens when the capa list is not changed), it can be changed by adding below to deviceConfig.yaml
#  type: dth
#  presentationId: {previous vid}
#  manufacturerName: SmartThingsCommunity
#  vid: {previous vid}
#  mnmn: SmartThingsCommunity
#  version: 0.0.1
######################################################################################
# Publish DTH with updated display keys
# Go to Groovy IDE and update VID in DTH
######################################################################################
