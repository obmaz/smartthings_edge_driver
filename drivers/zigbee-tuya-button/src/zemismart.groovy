/**
 *  Zemismart Button V1.6
 *
 *  Copyright 2020 YSB
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License. You may obtain a copy of the License at:
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
 *  on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
 *  for the specific language governing permissions and limitations under the License.
 *
 */

import groovy.json.JsonOutput
import physicalgraph.zigbee.clusters.iaszone.ZoneStatus
import physicalgraph.zigbee.zcl.DataType

metadata
        {
            definition (name: "Zemismart Button", namespace: "SangBoy", author: "YooSangBeom", ocfDeviceType: "x.com.st.d.remotecontroller", mcdSync: true)
                    {
                        capability "Actuator"
                        //capability "Battery"
                        capability "Button"
                        capability "Holdable Button"
                        capability "Refresh"
                        capability "Sensor"
                        capability "Health Check"
                        //1
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019, 000A", manufacturer: "_TZ3400_keyjqthh", model: "TS0041", deviceJoinName: "Zemismart Button", mnmn: "SmartThings", vid: "generic-2-button"
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019, 000A", manufacturer: "_TZ3400_tk3s5tyg", model: "TS0041", deviceJoinName: "Zemismart Button", mnmn: "SmartThings", vid: "generic-2-button"
                        //2
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019", manufacturer: "_TYZB02_keyjhapk", model: "TS0042", deviceJoinName: "Zemismart 2 Button", mnmn: "SmartThings", vid: "generic-2-button"
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019", manufacturer: "_TZ3400_keyjhapk", model: "TS0042", deviceJoinName: "Zemismart 2 Button", mnmn: "SmartThings", vid: "generic-2-button"
                        //3
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019, 000A", manufacturer: "_TZ3400_key8kk7r", model: "TS0043", deviceJoinName: "Zemismart 3 Button", mnmn: "SmartThings", vid: "generic-4-button"
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019", manufacturer: "_TYZB02_key8kk7r", model: "TS0043", deviceJoinName: "Zemismart 3 Button", mnmn: "SmartThings", vid: "generic-4-button"
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019, 000A", manufacturer: "_TZ3000_qzjcsmar", model: "TS0043", deviceJoinName: "Zemismart 3 Button", mnmn: "SmartThings", vid: "generic-4-button"
                        fingerprint inClusters: "0000, 000A, 0001, 0006", outClusters: "0019", manufacturer: "_TZ3000_rrjr1q0u", model: "TS0043", deviceJoinName: "Zemismart 3 Button", mnmn: "SmartThings", vid: "generic-4-button"
                        fingerprint inClusters: "0000, 000A, 0001, 0006", outClusters: "0019", manufacturer: "_TZ3000_bi6lpsew", model: "TS0043", deviceJoinName: "Zemismart 3 Button", mnmn: "SmartThings", vid: "generic-4-button"
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019", manufacturer: "_TZ3000_a7ouggvs", model: "TS0043", deviceJoinName: "Zemismart 3 Button", mnmn: "SmartThings", vid: "generic-4-button"
                        //4
                        //fingerprint inClusters: "0000, 000A, 0001, 0006", outClusters: "0019", manufacturer: "_TZ3000_vp6clf9d", model: "TS0044", deviceJoinName: "Zemismart Button", mnmn: "SmartThings", vid: "generic-4-button"
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019, 000A", manufacturer: "_TZ3000_vp6clf9d", model: "TS0044", deviceJoinName: "Zemismart 4 Button", mnmn: "SmartThings", vid: "generic-4-button"
                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019, 000A", manufacturer: "_TZ3000_dku2cfsc", model: "TS0044", deviceJoinName: "Zemismart 4 Button", mnmn: "SmartThings", vid: "generic-4-button"
                        fingerprint inClusters: "0000, 0001 0006", outClusters: "0019, 000A, ", manufacturer: "_TZ3000_xabckq1v", model: "TS004F", deviceJoinName: "Tuya Button", mnmn: "SmartThings", vid: "generic-4-button"

                        fingerprint inClusters: "0000, 0001, 0006", outClusters: "0019, 000A", manufacturer: "_TYZB01_cnlmkhbk", model: "TS0044", deviceJoinName: "Hejhome Smart Button", mnmn: "SmartThings", vid: "generic-4-button"
                    }

            tiles(scale: 2)
                    {
                        multiAttributeTile(name: "button", type: "generic", width: 2, height: 2)
                                {
                                    tileAttribute("device.button", key: "PRIMARY_CONTROL")
                                            {
                                                attributeState "pushed", label: "Pressed", icon:"st.Weather.weather14", backgroundColor:"#53a7c0"
                                                attributeState "double", label: "Pressed Twice", icon:"st.Weather.weather11", backgroundColor:"#53a7c0"
                                                attributeState "held", label: "Held", icon:"st.Weather.weather13", backgroundColor:"#53a7c0"
                                            }
                                }
                        valueTile("battery", "device.battery", decoration: "flat", inactiveLabel: false, width: 2, height: 2)
                                {
                                    state "battery", label: '${currentValue}% battery', unit: ""
                                }
                        standardTile("refresh", "device.refresh", inactiveLabel: false, decoration: "flat", width: 2, height: 2)
                                {
                                    state "default", action: "refresh.refresh", icon: "st.secondary.refresh"
                                }

                        main(["button"])
                        details(["button","battery", "refresh"])
                    }
        }

private getAttrid_Battery() { 0x0020 } //
private getCLUSTER_GROUPS() { 0x0004 }
private getCLUSTER_SCENES() { 0x0005 }
private getCLUSTER_WINDOW_COVERING() { 0x0102 }

private boolean isZemismart1gang()
{
    device.getDataValue("model") == "TS0041"
}

private boolean isZemismart2gang()
{
    device.getDataValue("model") == "TS0042"
}

private boolean isZemismart3gang()
{
    device.getDataValue("model") == "TS0043"
}

private boolean isZemismart4gang()
{
    device.getDataValue("model") == "TS0044"
}
private boolean isZemismart4gang_1()
{
    device.getDataValue("model") == "TS004F"
}

private Map getBatteryEvent(value)
{
    def result = [:]
    //result.value = value
    //Always value 0
    result.value = 100
    result.name = 'battery'
    result.descriptionText = "${device.displayName} battery was ${result.value}%"
    return result
}

private channelNumber(String dni)
{
    dni.split(":")[-1] as Integer
}

def parse(String description)
{
    log.debug "description is $description"
    def event = zigbee.getEvent(description)

    if (event) //non-standard
    {
        sendEvent(event)
        log.debug "sendEvent $event"
    }
    else
    {
        if ((description?.startsWith("catchall:")) || (description?.startsWith("read attr -")))
        {
            def descMap = zigbee.parseDescriptionAsMap(description)
/*
         if (descMap.clusterInt == 0x0001 && descMap.attrInt == getAttrid_Battery())
         {
            event = getBatteryEvent(zigbee.convertHexToInt(descMap.value))
         }
         else if (descMap.clusterInt == 0x0006)
         {
            event = parseNonIasButtonMessage(descMap)
         }
         if (descMap.clusterInt == zigbee.POWER_CONFIGURATION_CLUSTER && descMap.attrInt == getAttrid_Battery())
         {
            event = getBatteryEvent(zigbee.convertHexToInt(descMap.value))
         }
*/
            //if (descMap.clusterInt == 0x0006)
            //{
            event = parseNonIasButtonMessage(descMap)
            // }

        }
        def result = []
        if (event)
        {
            log.debug "Creating event: ${event}"
            result = createEvent(event)
        }
        else if (isBindingTableMessage(description))
        {
            Integer groupAddr = getGroupAddrFromBindingTable(description)
            if (groupAddr != null)
            {
                List cmds = addHubToGroup(groupAddr)
                result = cmds?.collect
                        {
                            new physicalgraph.device.HubAction(it)
                        }
            }
            else
            {
                groupAddr = 0x0000
                List cmds = addHubToGroup(groupAddr) +
                        zigbee.command(CLUSTER_GROUPS, 0x00, "${zigbee.swapEndianHex(zigbee.convertToHexString(groupAddr, 4))} 00")
                result = cmds?.collect
                        {
                            new physicalgraph.device.HubAction(it)
                        }
            }
        }
        return result
    }
    log.debug "allevent $event"
}
/*
private Map getBatteryResult(rawValue)
{
    log.debug "getBatteryResult"
    log.debug 'Battery'
    def linkText = getLinkText(device)

    def result = [:]

    def volts = rawValue / 10
    if(!(rawValue == 0 || rawValue == 255))
   	{
	   def minVolts = 2.1
	   def maxVolts = 3.0
	   def pct = (volts - minVolts) / (maxVolts - minVolts)
	   def roundedPct = Math.round(pct * 100)
	   if(roundedPct <=0)
	      roundedPct = 1
	   result.value = Math.min(100, roundedPct)
	   result.descriptionText = "${linkText} battery was ${result.value}%"
	   result.name = 'battery'
	}
}
def getBatteryPercentageResult(rawValue)
{
   log.debug "attrInt == 0x0021 : getBatteryPercentageResult"
   log.debug "Battery Percentage rawValue = ${rawValue} -> ${rawValue /2}%"
   def result = [:]

   if(0<= rawValue && rawValue <=200)
   {
     result.name = 'battery'
	 result.translatble = true
	 result.value = Math.round(rawValue/2)
	 result.descriptionText = "${device.displayName} battery was ${result.value}%"
   }
   return result
}
*/
private Map parseNonIasButtonMessage(Map descMap)
{
    def buttonState
    def buttonNumber = 0
    Map result = [:]

    if(device.getDataValue("model") == "TS004F")
    {

        //log.debug "data $descMap.data"
        //log.debug "clusterint $descMap.clusterInt"
        //log.debug "commandInt $descMap.commandInt"
        //log.debug "attrInt $descMap.attrInt"
        //1 -clusterint 6 commandInt 1
        //3 -clusterint 6 commandInt 0
        //2 -clusterint 8 data[0]==00
        //4 -clusterint 8 data[0]==01

        buttonState = "pushed"
        if (descMap.clusterInt == 0x0006)
        {
            if(descMap.commandInt == 1) //button 1 push
            {
                buttonNumber = 1
            }
            else if(descMap.commandInt == 0)//button 3 push
            {
                buttonNumber = 3
            }
        }
        else if(descMap.clusterInt == 0x0008)
        {
            if(descMap.data[0] == "00") //button 2 push
            {
                buttonNumber = 2
                if(descMap.commandInt == 1)//button 2 held
                {
                    buttonState = "held"
                }
            }
            else if(descMap.data[0] == "01")//button 4 push
            {
                buttonNumber = 4
                if(descMap.commandInt == 1)//button 4 held
                {
                    buttonState = "held"
                }
            }
        }


        if (buttonNumber !=0)
        {
            def descriptionText = "button $buttonNumber was $buttonState"
            result = [name: "button", value: buttonState, data: [buttonNumber: buttonNumber], descriptionText: descriptionText, isStateChange: true]
            sendButtonEvent(buttonNumber, buttonState)         //return createEvent(name: "button$buttonNumber", value: buttonState, data: [buttonNumber: buttonNumber], descriptionText: descriptionText, isStateChange: true)
        }
        result
    }
    else
    {
        if (descMap.clusterInt == 0x0006)
        {
            if(device.getDataValue("model") == "TS0044")
            {
                switch(descMap.sourceEndpoint)
                {
                    case "01":
                        buttonNumber = 3 //1
                        break
                    case "02":
                        buttonNumber = 4 //2
                        break
                    case "03":
                        buttonNumber = 2 //3
                        break
                    case "04":
                        buttonNumber = 1 //4
                        break
                }
            }
            else
            {
                switch(descMap.sourceEndpoint)
                {
                    case "01":
                        buttonNumber = 1
                        break
                    case "02":
                        buttonNumber = 2
                        break
                    case "03":
                        buttonNumber = 3
                        break
                    case "04":
                        buttonNumber = 4
                        break
                }
            }
            switch(descMap.data)
            {
                case "[00]":
                    buttonState = "pushed"
                    break
                case "[01]":
                    buttonState = "double"
                    break
                case "[02]":
                    buttonState = "held"
                    break
            }
            if (buttonNumber !=0)
            {
                def descriptionText = "button $buttonNumber was $buttonState"
                result = [name: "button", value: buttonState, data: [buttonNumber: buttonNumber], descriptionText: descriptionText, isStateChange: true]
                sendButtonEvent(buttonNumber, buttonState)
                //return createEvent(name: "button$buttonNumber", value: buttonState, data: [buttonNumber: buttonNumber], descriptionText: descriptionText, isStateChange: true)
            }
            result
        }
    }
}

private sendButtonEvent(buttonNumber, buttonState)
{
    def child = childDevices?.find { channelNumber(it.deviceNetworkId) == buttonNumber }
    if (child)
    {
        def descriptionText = "$child.displayName was $buttonState" // TODO: Verify if this is needed, and if capability template already has it handled
        log.debug "child $child"
        child?.sendEvent([name: "button", value: buttonState, data: [buttonNumber: 1], descriptionText: descriptionText, isStateChange: true])
    }
    else
    {
        log.debug "Child device $buttonNumber not found!"
    }
}

def refresh()
{
    //log.debug "Refreshing Battery"
    updated()
    //return zigbee.readAttribute(zigbee.POWER_CONFIGURATION_CLUSTER, getAttrid_Battery())
}

def configure()
{
    log.debug "Configuring Reporting, IAS CIE, and Bindings."
    def cmds = []

    return //zigbee.configureReporting(zigbee.POWER_CONFIGURATION_CLUSTER, getAttrid_Battery(), DataType.UINT8, 30, 21600, 0x01) +
    zigbee.enrollResponse() +
            //zigbee.readAttribute(zigbee.POWER_CONFIGURATION_CLUSTER, getAttrid_Battery()) +
            //zigbee.addBinding(zigbee.ONOFF_CLUSTER) +
            readDeviceBindingTable() // Need to read the binding table to see what group it's using
    cmds
}

private getButtonName(buttonNum)
{
    return "${device.displayName} " + buttonNum
}

private void createChildButtonDevices(numberOfButtons)
{
    state.oldLabel = device.label
    log.debug "Creating $numberOfButtons"
    log.debug "Creating $numberOfButtons children"

    for (i in 1..numberOfButtons)
    {
        log.debug "Creating child $i"
        def child = addChildDevice("smartthings", "Child Button", "${device.deviceNetworkId}:${i}", device.hubId,[completedSetup: true, label: getButtonName(i),
                                                                                                                  isComponent: true, componentName: "button$i", componentLabel: "buttton ${i}"])
        child.sendEvent(name: "supportedButtonValues",value: ["pushed","held","double"].encodeAsJSON(), displayed: false)
        child.sendEvent(name: "numberOfButtons", value: 1, displayed: false)
        child.sendEvent(name: "button", value: "pushed", data: [buttonNumber: 1], displayed: false)
    }
}
private void createChildButtonDevices_1(numberOfButtons)
{
    state.oldLabel = device.label
    log.debug "Creating $numberOfButtons"
    log.debug "Creating $numberOfButtons children"

    for (i in 1..numberOfButtons)
    {
        log.debug "Creating child $i"
        def child = addChildDevice("smartthings", "Child Button", "${device.deviceNetworkId}:${i}", device.hubId,[completedSetup: true, label: getButtonName(i),
                                                                                                                  isComponent: true, componentName: "button$i", componentLabel: "buttton ${i}"])
        if((i==2) || (i==4))
        {
            child.sendEvent(name: "supportedButtonValues",value: ["pushed","held"].encodeAsJSON(), displayed: false)
        }
        else
        {
            child.sendEvent(name: "supportedButtonValues",value: ["pushed"].encodeAsJSON(), displayed: false)
        }
        child.sendEvent(name: "numberOfButtons", value: 1, displayed: false)
        child.sendEvent(name: "button", value: "pushed", data: [buttonNumber: 1], displayed: false)
    }
}
def installed()
{
    def numberOfButtons
    if (isZemismart1gang())
    {
        numberOfButtons = 1
    }
    else if (isZemismart2gang())
    {
        numberOfButtons = 2
    }
    else if (isZemismart3gang())
    {
        numberOfButtons = 3
    }
    else if (isZemismart4gang())
    {
        numberOfButtons = 4
    }
    else if (isZemismart4gang_1())
    {
        numberOfButtons = 4
    }

    if(device.getDataValue("model") == "TS004F")
    {
        createChildButtonDevices_1(numberOfButtons) //
        sendEvent(name: "supportedButtonValues", value: ["pushed"].encodeAsJSON(), displayed: false)
    }
    else
    {
        createChildButtonDevices(numberOfButtons) //Todo
        sendEvent(name: "supportedButtonValues", value: ["pushed","held","double"].encodeAsJSON(), displayed: false)
    }
    sendEvent(name: "numberOfButtons", value: numberOfButtons , displayed: false)
    //sendEvent(name: "button", value: "pushed", data: [buttonNumber: 1], displayed: false)
    // Initialize default states
    numberOfButtons.times
            {
                sendEvent(name: "button", value: "pushed", data: [buttonNumber: it+1], displayed: false)
            }
    // These devices don't report regularly so they should only go OFFLINE when Hub is OFFLINE
    sendEvent(name: "DeviceWatch-Enroll", value: JsonOutput.toJson([protocol: "zigbee", scheme:"untracked"]), displayed: false)
}

def updated()
{
    log.debug "childDevices $childDevices"
    if (childDevices && device.label != state.oldLabel)
    {
        childDevices.each
                {
                    def newLabel = getButtonName(channelNumber(it.deviceNetworkId))
                    it.setLabel(newLabel)
                }
        state.oldLabel = device.label
    }
}


private Integer getGroupAddrFromBindingTable(description)
{
    log.info "Parsing binding table - '$description'"
    def btr = zigbee.parseBindingTableResponse(description)
    def groupEntry = btr?.table_entries?.find { it.dstAddrMode == 1 }
    if (groupEntry != null)
    {
        log.info "Found group binding in the binding table: ${groupEntry}"
        Integer.parseInt(groupEntry.dstAddr, 16)
    }
    else
    {
        log.info "The binding table does not contain a group binding"
        null
    }
}

private List addHubToGroup(Integer groupAddr)
{
    ["st cmd 0x0000 0x01 ${CLUSTER_GROUPS} 0x00 {${zigbee.swapEndianHex(zigbee.convertToHexString(groupAddr,4))} 00}","delay 200"]
}

private List readDeviceBindingTable()
{
    ["zdo mgmt-bind 0x${device.deviceNetworkId} 0","delay 200"]
}