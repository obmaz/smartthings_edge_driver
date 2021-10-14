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
    log.info("--------- Moon --------->> on_handler - component : ", command)
    local currentValue = device:get_latest_state("main", "switchLevel", "level", 0, nil)
    device.profile.components["main"]:emit_event(capabilities.switchLevel.level(currentValue + 1))
end

local function off_handler(driver, device, command)
    log.info("--------- Moon --------->> off_handler - component : ", command)
    local currentValue = device:get_latest_state("main", "switchLevel", "level", 0, nil)
    device.profile.components["button2"]:emit_event(capabilities.switchLevel.level(currentValue - 1))
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
    device.profile.components["main"]:emit_event(capabilities.switchLevel.level(0))
end

local configure_device = function(self, device)
    log.info("--------- Moon --------->> configure_device")
    device:configure()
    device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
end

--local device_init = function(self, device)
--    log.info("--------- Moon --------->> device_init")
--    device:set_component_to_endpoint_fn(component_to_endpoint)
--    device:set_endpoint_to_component_fn(endpoint_to_component)
--end

local sihas_people_counter_template = {
    supported_capabilities = {
        capabilities.switchLevel,
        capabilities.battery,
        capabilities.refresh
    },
    zigbee_handlers = {
        cluster = {
            -- zcl_clusters.OnOff.server.commands.OnOff.ID
            [0x0006] = {
                -- ZCLCommandId
                [zcl_clusters.OnOff.server.commands.Off.ID] = off_handler,
                [zcl_clusters.OnOff.server.commands.On.ID] = on_handler,
            },
            -- zcl_clusters.Level.server.commands.MoveToClosestFrequency.ID
            [0x0008] = {
                -- ZCLCommandId
                [zcl_clusters.Level.server.commands.Move.ID] = off_start_handler,
                [zcl_clusters.Level.server.commands.MoveWithOnOff.ID] = on_start_handler,
                [zcl_clusters.Level.server.commands.StopWithOnOff.ID] = stop_handler,
            }
        }
    },
    lifecycle_handlers = {
        added = device_added,
        doConfigure = configure_device,
        --init = device_init,
    }
}

defaults.register_for_default_handlers(sihas_people_counter_template, sihas_people_counter_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("sihas-people-counter", sihas_people_counter_template)
zigbee_driver:run()