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
local remapButton = "switch1"

local remapButtonTbl = {
    ["one"] = "switch1",
    ["two"] = "switch2",
    ["three"] = "switch3",
}

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")
    -- Workaround : Should emit or send to enable capabilities UI
    for key, value in pairs(device.profile.components) do
        log.info("--------- Moon --------->> device_added - component : ", key)
        device.profile.components[key]:emit_event(capabilities.switch.switch.on())
        device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
    end
end

local function handleOn(driver, device, command)
    log.info("--------- Moon --------->> handle_on - component : ", command.component)

    if command.component == remapButton then
        command.component = "main"
    end

    if command.component == "main" then
        device.profile.components[remapButton]:emit_event(capabilities.switch.switch.on())
    end

    device.profile.components[command.component]:emit_event(capabilities.switch.switch.on())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.On(device))
end

local function handleOff(driver, device, command)
    log.info("--------- Moon --------->> handle_off - component : ", command.component)

    if command.component == remapButton then
        command.component = "main"
    end

    if command.component == "main" then
        device.profile.components[remapButton]:emit_event(capabilities.switch.switch.off())
    end

    -- Note : The logic is the same, but it uses endpoint.
    --local endpoint = device:get_endpoint_for_component_id(command.component)
    --device:emit_event_for_endpoint(endpoint, capabilities.switch.switch.off())
    --device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(endpoint))
    device.profile.components[command.component]:emit_event(capabilities.switch.switch.off())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.Off(device))
end

local component_to_endpoint = function(device, component_id)
    log.info("--------- Moon --------->> component_to_endpoint - component_id : ", component_id)

    if component_id == "main" then
        component_id = remapButton
    end

    local ep_num = component_id:match("switch(%d)")
    return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
end

local endpoint_to_component = function(device, ep)
    log.info("--------- Moon --------->> endpoint_to_component - endpoint : ", ep)

    local component_id = string.format("switch%d", ep)

    if component_id == remapButton then
        --syncComponent(device, "on")
    end

    return component_id

    --if ep == device.fingerprinted_endpoint_id then
    --    return "main"
    --else
    --    return string.format("switch%d", ep)
    --end
end

local device_info_changed = function(driver, device, event, args)
    remapButton = remapButtonTbl[device.preferences.remapButton]
    syncComponent(device, "off")
end

function syncComponent(device, reverse)
    local status = device:get_latest_state(remapButton, "switch", "switch", "off", nil)
    if status == reverse then
        device.profile.components["main"]:emit_event(capabilities.switch.switch.off())
    else
        device.profile.components["main"]:emit_event(capabilities.switch.switch.on())
    end
end

local device_init = function(self, device)
    log.info("--------- Moon --------->> device_init")
    device:set_component_to_endpoint_fn(component_to_endpoint) -- get_endpoint_for_component_id
    device:set_endpoint_to_component_fn(endpoint_to_component)
    remapButton = remapButtonTbl[device.preferences.remapButton]
end

local zigbee_tuya_switch_driver_template = {
    supported_capabilities = {
        capabilities.switch,
        capabilities.refresh
    },
    -- UI를 누를때 호출
    capability_handlers = {
        [capabilities.switch.ID] = {
            [capabilities.switch.commands.on.NAME] = handleOn,
            [capabilities.switch.commands.off.NAME] = handleOff
        }
    },
    lifecycle_handlers = {
        added = device_added,
        init = device_init,
        infoChanged = device_info_changed,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_switch_driver_template, zigbee_tuya_switch_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-switch", zigbee_tuya_switch_driver_template)
zigbee_driver:run()

--  onOff: {ID: 0, type: DataType.boolean},
--  tuyaBacklightMode: {ID: 0x8001, type: DataType.enum8}, ?????
--        <ZigbeeDevice: fb5ec176-64fc-400e-b8fa-6fd0abec0f4f [0xD261] (Tuya Wall Switch 2 Gang)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_add
--r: 0xD261, src_endpoint: 0x00, dest_addr: 0x0000, dest_endpoint: 0x00, profile: 0x0000, cluster: 0x8001 >, lqi: 0xFF, rssi: -63, body_length: 0x000C, < ZDOMessageBody || < ZDOHeader || seqno: 0x14 >, GenericBody:  00 FE 77 11 FE FF E
--C 86 CC 89 A1 > >

