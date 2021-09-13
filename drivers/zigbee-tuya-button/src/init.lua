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

local handle_pushed = function(driver, device, zb_rx)
    log.info("--------- Moon --------->> button_handler")

    device.profile.components["main"]:emit_event(capabilities.button.button.pushed())
    device.profile.components["button2"]:emit_event(capabilities.button.button.pushed())
    device.profile.components["button3"]:emit_event(capabilities.button.button.pushed())
    device.profile.components["button4"]:emit_event(capabilities.button.button.pushed())
end

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")

    for key,value in pairs(device.profile.components) do
        log.info("--------- Moon --------->> device_added - component : ", key)
        device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
        device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
    end
end

local configure_device = function(self, device)
    log.info("--------- Moon --------->> configure_device")

    device:configure()
    device:send(device_management.build_bind_request(device, zcl_clusters.OnOff.ID, device.driver.environment_info.hub_zigbee_eui))
    device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
end

local function component_to_endpoint(device, component_id)
    log.info("--------- Moon --------->> component_to_endpoint - component_id : ", component_id)
    if component_id == "main" then
        return device.fingerprinted_endpoint_id
    else
        local ep_num = component_id:match("button(%d)")
        return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
    end
end

local function endpoint_to_component(device, ep)
    log.info("--------- Moon --------->> endpoint_to_component - endpoint : ", ep)
    if ep == device.fingerprinted_endpoint_id then
        return "main"
    else
        return string.format("button%d", ep)
    end
end

local device_init = function(self, device)
    log.info("--------- Moon --------->> device_init")
    device:set_component_to_endpoint_fn(component_to_endpoint)
    device:set_endpoint_to_component_fn(endpoint_to_component)
end

local zigbee_tuya_button_driver_template = {
    supported_capabilities = {
        capabilities.button,
        capabilities.battery,
        capabilities.refresh
    },
    -- zigbee 로 들어오는 신호 = 리모콘 버튼을 누를때
    -- local OnOffCluster = (require "st.zigbee.zcl.clusters").OnOffCluster
    zigbee_handlers = {
        cluster = {
            [zcl_clusters.OnOff.ID] = {
                [0x00] = handle_pushed, -- off == [0x00]
                [0x01] = handle_pushed, -- on
                [0x02] = handle_pushed,  -- toggle
                [0x04] = handle_pushed,  -- toggle
                [0x0104] = handle_pushed,  -- toggle
            }
        },
    },
    lifecycle_handlers = {
        added = device_added,
        --doConfigure = configure_device,
        init = device_init,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_button_driver_template, zigbee_tuya_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-button", zigbee_tuya_button_driver_template)
zigbee_driver:run()