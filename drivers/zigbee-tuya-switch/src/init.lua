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

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")

    device:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
    device:emit_event(capabilities.button.button.pushed())

    for i, v in ipairs(comp) do
        log.info("device_added ", i, v)

        device.profile.components[v]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
        device.profile.components[v]:emit_event(capabilities.button.button.pushed())
    end
end

local function custom_on_off_attr_handler(driver, device, value, zb_rx)
    log.info("custom_on_off_attr_handler")
    device:emit_event(value.value and capabilities.switch.switch.On() or capabilities.switch.switch.Off())
end

local function handle_on(driver, device, command)
    log.info("Send on command to device : handle_on")
    device:send(zcl_clusters.OnOff.server.commands.On(device))
    --device:send(zcl_clusters.OnOff.server.commands.On(device):to_endpoint(0x01))
    --device:send(zcl_clusters.OnOff.server.commands.On(device):to_endpoint(0x02))
    device:emit_event(capabilities.switch.switch.on())
end

local function handle_off(driver, device, command)
    log.info("Send off command to device : handle_off")
    device:send(zcl_clusters.OnOff.server.commands.Off(device))
    --device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(0x01))
    --device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(0x02))
    device:emit_event(capabilities.switch.switch.off())
end


local function component_to_endpoint(device, component_id)
    log.info("--------- Moon --------->> component_to_endpoint component_id : ", component_id)

    if component_id == "main" then
        return device.fingerprinted_endpoint_id
    else
        local ep_num = component_id:match("switch(%d)")
        log.info("--------- Moon --------->> component_to_endpoint ep_num : ", ep_num)
        return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
    end
end

local function endpoint_to_component(device, ep)
    log.info("--------- Moon --------->> endpoint_to_component : ", device.fingerprinted_endpoint_id)
    if ep == device.fingerprinted_endpoint_id then
        log.info("--------- Moon --------->> endpoint_to_component : device.fingerprinted_endpoint_id == ep", ep)
        return "main"
    else
        log.info("--------- Moon --------->> endpoint_to_component : device.fingerprinted_endpoint_id != ep", ep)
        return "switch2"
    end
end

local device_init = function(self, device)
    log.info("--------- Moon --------->> device_init")
    device:set_component_to_endpoint_fn(component_to_endpoint)
    device:set_endpoint_to_component_fn(endpoint_to_component)
end

local zigbee_tuya_switch_driver_template = {
    supported_capabilities = {
        capabilities.switch,
        capabilities.refresh
    },
    capability_handlers = {
        [capabilities.switch.ID] =
        {
            [capabilities.switch.commands.on.NAME] = handle_on,
            [capabilities.switch.commands.off.NAME] = handle_off
        }
    },
    attr = {
        [zcl_clusters.OnOff.ID] = {
            [zcl_clusters.OnOff.attributes.OnOff.ID] = custom_on_off_attr_handler
        }
    },
    lifecycle_handlers = {
        -- https://developer-preview.smartthings.com/edge-device-drivers/driver.html
        added = device_added,
        --doConfigure = configure_device,
        init = device_init,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_switch_driver_template, zigbee_tuya_switch_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-switch", zigbee_tuya_switch_driver_template)
zigbee_driver:run()

-- UI 클릭
--  <ZigbeeDevice: d2a67145-90b2-4025-912b-adfc7c3f27ed [0x8ECD] (Tuya 2 Switch)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x8ECD, src
--_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -62, body_length: 0x0007, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x18, seqno: 0x17, ZCLCommandId: 0x0A >, < ReportAttr
--ibute || < AttributeRecord || AttributeId: 0x0000, DataType: Boolean, OnOff: true > > > >

-- 물리버튼 클릭
--  <ZigbeeDevice: d2a67145-90b2-4025-912b-adfc7c3f27ed [0x8ECD] (Tuya 2 Switch)> emitting event: {"capability_id":"switch","state":{"value":"off"},"attribute_id":"switch","compone
--nt_id":"main"}