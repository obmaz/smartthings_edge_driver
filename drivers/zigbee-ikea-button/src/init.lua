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

local incValue = 10

local function updateIncValue(device)
    incValue = math.floor(device.preferences.incValue)
    return
end

local function level_handler(driver, device, command)
    log.info("--------- Moon --------->> level_handler - component : ", command.args.level)
    device.profile.components["main"]:emit_event(capabilities.switchLevel.level(command.args.level))
end

local function on_handler(driver, device, command)
    log.info("--------- Moon --------->> on_handler - component : ", command)
    local currentValue = device:get_latest_state("main", "switchLevel", "level", 50, nil)
    device.profile.components["main"]:emit_event(capabilities.switchLevel.level(currentValue + incValue))
end

local function off_handler(driver, device, command)
    log.info("--------- Moon --------->> off_handler - component : ", command)
    local currentValue = device:get_latest_state("main", "switchLevel", "level", 50, nil)
    device.profile.components["main"]:emit_event(capabilities.switchLevel.level(currentValue - incValue))
end

local function on_start_handler(driver, device, command)
    log.info("--------- Moon --------->> on_start_handler - component : ", command)
end

local function off_start_handler(driver, device, command)
    log.info("--------- Moon --------->> off_start_handler - component : ", command)
end

local function stop_handler(driver, device, command)
    log.info("--------- Moon --------->> stop_handler - component : ", command)
end

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")
    updateIncValue(device)
    device.profile.components["main"]:emit_event(capabilities.switchLevel.level(50))
end

local configure_device = function(self, device)
    log.info("--------- Moon --------->> configure_device")
    device:configure()
    device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
end

local device_info_changed = function(driver, device, event, args)
    updateIncValue(device)
end

local zigbee_ikea_button_driver_template = {
    supported_capabilities = {
        capabilities.switchLevel,
        capabilities.battery,
        capabilities.refresh
    },
    capability_handlers = {
        [capabilities.switchLevel.ID] = {
            [capabilities.switchLevel.commands.setLevel.NAME] = level_handler,
        }
    },
    zigbee_handlers = {
        cluster = {
            -- 0x0006
            [zcl_clusters.OnOff.server.commands.OnOff.ID] = {
                -- ZCLCommandId
                [zcl_clusters.OnOff.server.commands.Off.ID] = off_handler,
                [zcl_clusters.OnOff.server.commands.On.ID] = on_handler,
            },
            -- 0x0008
            [zcl_clusters.Level.server.commands.MoveToClosestFrequency.ID] = {
                -- ZCLCommandId
                [zcl_clusters.Level.server.commands.Move.ID] = off_start_handler,
                [zcl_clusters.Level.server.commands.MoveWithOnOff.ID] = on_start_handler,
                [zcl_clusters.Level.server.commands.StopWithOnOff.ID] = stop_handler,
            }
        }
    },
    lifecycle_handlers = {
        added = device_added,
        infoChanged = device_info_changed,
        doConfigure = configure_device,
    }
}

defaults.register_for_default_handlers(zigbee_ikea_button_driver_template, zigbee_ikea_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-ikea-button", zigbee_ikea_button_driver_template)
zigbee_driver:run()