#!/bin/bash
######################################################################################
# Smartthings CLI        : https://github.com/SmartThingsCommunity/smartthings-cli
# Capabilities Reference : https://smartthings.developer.samsung.com/docs/api-ref/capabilities.html
# Custom Capabilities    : https://smartthings.developer.samsung.com/docs/Capabilities/custom-capabilities.html
# Community              : https://community.smartthings.com/t/custom-capability-and-cli-developer-preview/197296
# Presentation check     : https://api.smartthings.com/v1/capabilities/imageafter45121.thermostatCoolingSetpoint/1/presentation
######################################################################################
# Capability is device definition
# Presentation is control definition of capability
# VID is a set of Capabilities
######################################################################################
# Creating Custom Capabilities
# It generates the uid like "imageafter45121.channel"
#  $smartthings capabilities:create -n imageafter45121
#  $smartthings capabilities:create -n imageafter45121 --input channel.yaml
#-------------------------------------------------------------------------------------
# Show capabilities
#  $smartthings capabilities
#-------------------------------------------------------------------------------------
# Delete capability
#  $smartthings capabilities:delete {id}
######################################################################################
# Creating Capabilities Presentations
# it might register custom capability to smartthings server
#  $smartthings capabilities:presentation:create imageafter45121.channel 1 --yaml --input=divoom-channel-presentation.yaml
#-------------------------------------------------------------------------------------
# Update Presentation custom capability
#  $smartthings capabilities:presentation:update imageafter45121.channel 1 --yaml --input=divoom-channel-presentation.yaml