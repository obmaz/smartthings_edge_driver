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
local zcl_clusters = require "st.zigbee.zcl.clusters"

function button_handler (driver, device, zb_rx)
    log.info("--------- Moon --------->> button_handler")

    local ep = zb_rx.address_header.src_endpoint.value
    local component_id = string.format("button%d", ep)

    if ep == 1 then
        component_id = "main"
    end

    -- 00: click, 01: double click, 02: hold_release
    local clickType = string.byte(zb_rx.body.zcl_body.body_bytes)
    if clickType == 0 then
        local ev = capabilities.button.button.pushed()
        ev.state_change = true
        device.profile.components[component_id]:emit_event(ev)
    end

    if clickType == 1 then
        local ev = capabilities.button.button.double()
        ev.state_change = true
        device.profile.components[component_id]:emit_event(ev)
    end

    if clickType == 2 then
        local ev = capabilities.button.button.held()
        ev.state_change = true
        device.profile.components[component_id]:emit_event(ev)
    end
end

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")

    for key, value in pairs(device.profile.components) do
        log.info("--------- Moon --------->> device_added - component : ", key)
        device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
        device.profile.components[key]:emit_event(capabilities.button.button.pushed())
    end
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

local zigbee_tuya_button_driver_template = {
    supported_capabilities = {
        capabilities.button,
        capabilities.battery,
        capabilities.refresh
    },
    -- zigbee 로 들어오는 신호 = 리모콘 버튼을 누를때
    zigbee_handlers = {
        cluster = {
            -- zcl_clusters.OnOff.server.commands.OnOff.ID
            [0x0006] = {
                -- ZCLCommandId
                [0xFD] = button_handler
            }
        }
    },
    lifecycle_handlers = {
        added = device_added,
        doConfigure = configure_device,
        --init = device_init,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_button_driver_template, zigbee_tuya_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-button", zigbee_tuya_button_driver_template)
zigbee_driver:run()


--< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x3F9D, src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -56, body_length: 0x0004, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x05, ZCLCommandId: 0xFD >, GenericBody:  00 > >

--< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x3F9D, src_endpoint: 0x01, dest_addr: 0x0000, dest_e
--ndpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -55, body_length: 0x0004, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x06, ZCLCommandId: 0xFD >, GenericBody:  01 > >

--< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x3F9D, src_endpoint: 0x01, dest_addr: 0x0000, dest_e
--ndpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xF1, rssi: -55, body_length: 0x0004, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x07, ZCLCommandId: 0xFD >, GenericBody:  02 > >
