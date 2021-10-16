-- SiHAS People Counter
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local log = require "log"
local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local zcl_clusters = require "st.zigbee.zcl.clusters"

local function on_handler(driver, device, command)
    log.info("<<---- Moon ---->> on_handler - component : ", command)
    local currentValue = device:get_latest_state("main", "switchLevel", "level", 0, nil)
    device.profile.components["main"]:emit_event(capabilities.switchLevel.level(currentValue + 1))
end

local function off_handler(driver, device, command)
    log.info("<<---- Moon ---->> off_handler - component : ", command)
    local currentValue = device:get_latest_state("main", "switchLevel", "level", 0, nil)
    device.profile.components["button2"]:emit_event(capabilities.switchLevel.level(currentValue - 1))
end

local function on_start_handler(driver, device, command)
    log.info("<<---- Moon ---->> on_start_handler - component : ", command)
end

local function off_start_handler(driver, device, command)
    log.info("<<---- Moon ---->> off_start_handler - component : ", command)
end

local function stop_handler(driver, device, command)
    log.info("<<---- Moon ---->> stop_handler - component : ", command)
end

local device_added = function(driver, device)
    log.info("<<---- Moon ---->> device_added")
    device.profile.components["main"]:emit_event(capabilities.switchLevel.level(0))
end

local configure_device = function(self, device)
    log.info("<<---- Moon ---->> configure_device")
    device:configure()
    device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
end

--local device_init = function(self, device)
--    log.info("<<---- Moon ---->> device_init")
--    device:set_component_to_endpoint_fn(component_to_endpoint)
--    device:set_endpoint_to_component_fn(endpoint_to_component)
--end

local sihas_people_counter_template = {
    supported_capabilities = {
        capabilities.switchLevel,
        capabilities.battery,
        capabilities.refresh
    },
    capability_handlers = {
        [capabilities.switchLevel.ID] = {
            [capabilities.switchLevel.commands.setLevel.level] = on_handler,
        }
    },
    zigbee_handlers = {
        cluster = {
            [0x01] = {
                -- ZCLCommandId
                [0x01] = off_start_handler,

            }
        }
    },
    lifecycle_handlers = {
        added = device_added,
        doConfigure = configure_device,
        --init = device_init,
    }
}

-- refersh
--     refreshCmds += zigbee.readAttribute(ANALOG_INPUT_BASIC_CLUSTER, ANALOG_INPUT_BASIC_PRESENT_VALUE_ATTRIBUTE)
-- configCmds += zigbee.configureReporting(zigbee.POWER_CONFIGURATION_CLUSTER, POWER_CONFIGURATION_BATTERY_VOLTAGE_ATTRIBUTE, DataType.UINT8, 30, 21600, 0x01/*100mv*1*/)
--configCmds += zigbee.configureReporting(ANALOG_INPUT_BASIC_CLUSTER, ANALOG_INPUT_BASIC_PRESENT_VALUE_ATTRIBUTE, DataType.FLOAT4, 1, 600, 1)
defaults.register_for_default_handlers(sihas_people_counter_template, sihas_people_counter_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("sihas-people-counter", sihas_people_counter_template)
zigbee_driver:run()
--https://github.com/SmartThingsCommunity/SmartThingsPublic/blob/3f1cdd530445f2d93e0a4c6eca5a7823e3ee5563/devicetypes/shinasys/sihas-multipurpose-sensor.src/sihas-multipurpose-sensor.groovy

--        <ZigbeeDevice: 2825c729-0dd9-4757-851a-60f438e23c99 [0x6074] (SiHAS People Counter)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr:
--0x6074, src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: PowerConfiguration >, lqi: 0xFF, rssi: -51, body_length: 0x0008, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x18, seqno: 0x18, ZCLCommand
--Id: 0x01 >, < ReadAttributeReponse || < AttributeRecord || AttributeId: 0x0021, ZclStatus: SUCCESS, DataType: Uint8, BatteryPercentageRemaining: 0xC8 > > > >

--	01 0104 0402 01 05 0000 0004 0003 0001 000C 05 0000 0004 0003 0019 0006
--application: 01
--endpointId: 01
--firmwareFullVersion: 00000001
--firmwareImageType: 5632
--firmwareManufacturerCode: 4151
--manufacturer: ShinaSystem
--model: CSM-300Z
--zigbeeNodeType: SLEEPY_END_DEVICE