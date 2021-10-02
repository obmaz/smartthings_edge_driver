-- Zigbee Tuya Button
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
local device_management = require "st.zigbee.device_management"
local zcl_clusters = require "st.zigbee.zcl.clusters"

local remapButtonTbl = {
    ["one"] = "switch1",
    ["two"] = "switch2",
    ["three"] = "switch3",
}
local incValue = 10

local function handleOn(driver, device, command)
    log.info("--------- Moon --------->> handle_on - component : ", command)
end

local function handleOff(driver, device, command)
    log.info("--------- Moon --------->> handle_off - component : ", command)
end

local function handleOffStart(driver, device, command)
    log.info("--------- Moon --------->> handleOffStart - component : ", command)
end

local function handleOnStart(driver, device, command)
    log.info("--------- Moon --------->> handleOnStart - component : ", command)
end

local function handleStop(driver, device, command)
    log.info("--------- Moon --------->> handleStop - component : ", command)
end

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")
    incValue = device.preferences.incValue
    device.profile.components[key]:emit_event(capabilities.switchLevel.level(50))
    -- \lua_libs-api_v0\st\zigbee\generated\zcl_clusters\OnOff\server\commands
    --device:send_to_component(key, zcl_clusters.Level.server.commands.Stop())
    --device:send_to_component(key, zcl_clusters.Level.server.commands.Move())
    --device:send_to_component(key, zcl_clusters.Level.server.commands.MoveToLevel())
end

local configure_device = function(self, device)
    log.info("--------- Moon --------->> configure_device")
    device:configure()
    --device:send(device_management.build_bind_request(device, 0x0008, device.driver.environment_info.hub_zigbee_eui))
    --device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
end

local device_info_changed = function(driver, device, event, args)
    incValue = device.preferences.incValue
end

local zigbee_tuya_button_driver_template = {
    supported_capabilities = {
        capabilities.switchLevel,
        --capabilities.battery,
        capabilities.refresh
    },
    capability_handlers = {
        [capabilities.switchLevel.ID] = {
            [0x00] = handleOff,
            [0x01] = handleOn,
        }
    },
    zigbee_handlers = {
        cluster = {
            [0x0006] = {
                [0x00] = handleOff,
                [0x01] = handleOn,
            },
            [0x0008] = {
                [0x01] = handleOffStart,
                [0x05] = handleOnStart,
                [0x07] = handleStop,
            }
        }
    },
    lifecycle_handlers = {
        added = device_added,
        infoChanged = device_info_changed,
        doConfigure = configure_device,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_button_driver_template, zigbee_tuya_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-ikea-button", zigbee_tuya_button_driver_template)
zigbee_driver:run()