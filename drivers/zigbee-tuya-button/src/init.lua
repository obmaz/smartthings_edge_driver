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

local function handle_on(driver, device, command)
    log.info("--------- Moon --------->> 1111111111111111111111111111111111111111111111111111111111111111111111")
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

    for key, value in pairs(device.profile.components) do
        log.info("--------- Moon --------->> device_added - component : ", key)
        device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
        device.profile.components[key]:emit_event(capabilities.button.button.pushed())
    end
end

local foo

local configure_device = function(self, device)
    --foo ="0x"..device.device_network_id
    foo = tonumber(device.device_network_id)
    log.info("--------- Moon --------->> configure_device", device.device_network_id)

    device:configure()
    --    ["zdo mgmt-bind 0x${device.deviceNetworkId} 0","delay 200"]
    --device:send(device_management.build_bind_request(device, foo, device.driver.environment_info.hub_zigbee_eui))
    device:send(device_management.build_bind_request(device, 0x0006, device.driver.environment_info.hub_zigbee_eui))
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
    },
    -- zigbee 로 들어오는 신호 = 리모콘 버튼을 누를때
    zigbee_handlers = {
        attr = {
            [0x0006] = { -- zcl_clusters.OnOff.ID
                [0x00] = handle_on,
                [0x01] = handle_on
                --[zcl_clusters.OnOff.commands.server.Off.ID] = handle_on, -- on
            }
        },
        cluster = {
            [0x0008] = { -- zcl_clusters.OnOff.ID
                [0x00] = handle_on,
                [0x01] = handle_on
                --[zcl_clusters.OnOff.commands.server.Off.ID] = handle_on, -- on
            },
            [0x0006] = { -- zcl_clusters.OnOff.ID
                [0x00] = handle_on,
                [0x01] = handle_on
                --[zcl_clusters.OnOff.commands.server.Off.ID] = handle_on, -- on
            }
        },
        attr = {
            [zcl_clusters.OnOff.ID] = {
                [0x00] = handle_on,
                [0x01] = handle_on
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
local zigbee_driver = ZigbeeDriver("zigbee-tuya-button", zigbee_tuya_button_driver_template)
zigbee_driver:run()

-- https://github.com/YooSangBeom/SangBoyST/blob/master/devicetypes/sangboy/zemismart-button.src/zemismart-button.groovy
--01 0104 0000 01 03 0000 0001 0006 02 0019 000A
--<ZigbeeDevice: bfb32008-2365-4292-bcfc-20a81ec34301 [0x5595] (Tuya 4 Button)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x5595,
--src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -64, body_length: 0x0004, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x5A, ZCLCommandId: 0xFD >,
-- GenericBody:  00 > >


--*zigbee switch
--<ZigbeeDevice: 133b2345-22c2-493b-aac6-536ffeb2f121 [0x3029] (Tuya Wall Gang)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0--x3029,
-- src_endpoint: 0x02, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -62, body_length: 0x0005, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x08, seqno: 0x3F, ZCLCommandId: 0x0B >, <
--DefaultResponse || cmd: 0x00, ZclStatus: SUCCESS > > >