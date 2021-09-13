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

    for key,value in pairs(device.profile.components) do
        log.info("--------- Moon --------->> device_added - component : ", key)
        device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
        device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
    end
end

--local configure_device = function(self, device)
--    log.info("--------- Moon --------->> configure_device")
--
--    device:configure()
--    device:send(device_management.build_bind_request(device, zcl_clusters.OnOff.ID, device.driver.environment_info.hub_zigbee_eui))
--    device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
--end

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
        capabilities.switch,
        capabilities.refresh
    },
    -- zigbee 로 들어오는 신호 = 리모콘 버튼을 누를때
    zigbee_handlers = {
        cluster = {
            [zcl_clusters.OnOff.ID] = {
                [0x00] = handle_on, -- off == [0x00]
                [0x01] = handle_on, -- on
                [0x02] = handle_on,  -- toggle
                [0x04] = handle_pushed,  -- toggle
                [0x0104] = handle_pushed,  -- toggle
            }
        },
    },
    --capability_handlers = {
    --    [capabilities.button.ID] = {
    --        [capabilities.switch.commands.on.NAME] = handle_on,
    --        [capabilities.switch.commands.off.NAME] = handle_off
    --    }
    --},
    lifecycle_handlers = {
        added = device_added,
        --doConfigure = configure_device,
        init = device_init,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_button_driver_template, zigbee_tuya_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-button", zigbee_tuya_button_driver_template)
zigbee_driver:run()

--<ZigbeeDevice: f0e9af18-b048-44ac-8905-586e7a61b718 [0x1BBC] (Tuya 4 Button)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x1BBC,
--src_endpoint: 0x04, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -61, body_length: 0x0004, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x16, ZCLCommandId: 0xFD >, GenericB
--ody:  00 > >

--*zigbee switch
--<ZigbeeDevice: 133b2345-22c2-493b-aac6-536ffeb2f121 [0x3029] (Tuya Wall Switch 2 Gang)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0
--x3029, src_endpoint: 0x02, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -62, body_length: 0x0005, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x08, seqno: 0x3F, ZCLCommandId: 0x0B >, <
--DefaultResponse || cmd: 0x00, ZclStatus: SUCCESS > > >
