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

function handle_pushed (driver, device, zb_rx)
    log.info("--------- Moon --------->> button_handler")

    device.profile.components["main"]:emit_event(capabilities.button.button.pushed())
    device.profile.components["button2"]:emit_event(capabilities.button.button.pushed())
    device.profile.components["button3"]:emit_event(capabilities.button.button.pushed())
    device.profile.components["button4"]:emit_event(capabilities.button.button.pushed())
end

local function handle_on(driver, device, command)
    log.info("--------- Moon --------->> handle_on - component : ", command.component)
    device.profile.components[command.component]:emit_event(capabilities.button.button.pushed())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.On(device))
end

local function handle_off(driver, device, command)
    log.info("--------- Moon --------->> handle_off - component : ", command.component)
    --아래와 같이 endpoint를 구해서 호출도 가능, endpoint 값 조작이 필요할 경우 사용
    --local endpoint = device:get_endpoint_for_component_id(command.component)
    --device:emit_event_for_endpoint(endpoint, capabilities.switch.switch.off())
    --device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(endpoint))
    device.profile.components[command.component]:emit_event(capabilities.button.button.pushed())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.Off(device))
end

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")

    --Add the manufacturer-specific attributes to generate their configure reporting and bind requests
    --for capability_id, configs in pairs(common.get_cluster_configurations(device:get_manufacturer())) do
    --    if device:supports_capability_by_id(capability_id) then
    --        for _, config in pairs(configs) do
    --            device:add_configured_attribute(config)
    --            device:add_monitored_attribute(config)
    --            log.info("--------- Moon --------->> device_added config", config)
    --        end
    --    end
    --end
    --device:emit_event(capabilities.button.supportedButtonValues({"pushed", "held"}))
    --device:emit_event(capabilities.button.button.pushed())

    for key, value in pairs(device.profile.components) do
        log.info("--------- Moon --------->> device_added - component : ", key)
        device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
        device.profile.components[key]:emit_event(capabilities.button.button.pushed())
        device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
    end
end

local foo

local configure_device = function(self, device)
    log.info("--------- Moon --------->> configure_device")
    device:configure()
    --foo ="0x"..device.device_network_id
    --foo = tonumber(device.device_network_id)
    --    ["zdo mgmt-bind 0x${device.deviceNetworkId} 0","delay 200"]
    --device:send(device_management.build_bind_request(device, foo, device.driver.environment_info.hub_zigbee_eui))
    --device:send(device_management.build_bind_request(device, 0x0006, device.driver.environment_info.hub_zigbee_eui))

    --device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
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
        --capabilities.battery,
        --capabilities.refresh
    },
    -- zigbee 로 들어오는 신호 = 리모콘 버튼을 누를때
    zigbee_handlers = {
        cluster = {
            [0x06] = { -- zcl_clusters.OnOff.ID
                [0x00] = handle_pushed,
                [0x01] = handle_pushed
                --[zcl_clusters.OnOff.commands.server.Off.ID] = handle_on, -- on
            }
        },
        attr = {
            [zcl_clusters.OnOff.ID] = {
                [0x00] = handle_pushed,
                [0x01] = handle_pushed
            }
        }
    },
    lifecycle_handlers = {
        added = device_added,
        doConfigure = configure_device,
        init = device_init,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_button_driver_template, zigbee_tuya_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-ikea-button", zigbee_tuya_button_driver_template)
zigbee_driver:run()