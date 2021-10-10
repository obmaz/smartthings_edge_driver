-- Zigbee Tuya Switch
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

local remapSwitchTbl = {
    ["one"] = "switch1",
    ["two"] = "switch2",
    ["three"] = "switch3",
}

local function getRemapSwitch(device)
    remapSwitch = device.preferences.remapSwitch

    -- workaround: even if driver is updated, the profile does not reload
    -- so if preference variable is changed in profile, device does not use new varialbe
    if remapSwitch == nil then
        remapSwitch = device.preferences.remapButton
    end

    log.info("--------- Moon --------->> remapSwitch: ", remapSwitch)

    if remapSwitch == nil then
        return "main"
    else
        return remapSwitchTbl[remapSwitch]
    end
end

local on_handler = function(driver, device, command)
    log.info("--------- Moon --------->> on_handler - component : ", command.component)

    if command.component == "main" or command.component == getRemapSwitch(device) then
        device.profile.components["main"]:emit_event(capabilities.switch.switch.on())
        command.component = getRemapSwitch(device)
    end

    device.profile.components[command.component]:emit_event(capabilities.switch.switch.on())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.On(device))
end

local off_handler = function(driver, device, command)
    log.info("--------- Moon --------->> off_handler - component : ", command.component)

    if command.component == "main" or command.component == getRemapSwitch(device) then
        device.profile.components["main"]:emit_event(capabilities.switch.switch.off())
        command.component = getRemapSwitch(device)
    end

    -- Note : The logic is the same, but it uses endpoint.
    --local endpoint = device:get_endpoint_for_component_id(command.component)
    --device:emit_event_for_endpoint(endpoint, capabilities.switch.switch.off())
    --device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(endpoint))
    device.profile.components[command.component]:emit_event(capabilities.switch.switch.off())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.Off(device))
end

local received_handler = function(driver, device, OnOff, zb_rx)
    log.info("--------- Moon --------->> received_handler")

    local ep = zb_rx.address_header.src_endpoint.value
    local component_id = string.format("switch%d", ep)

    local clickType = OnOff.value
    local ev = capabilities.switch.switch.off()
    if clickType == true then
        ev = capabilities.switch.switch.on()
    end

    ev.state_change = true
    if component_id == getRemapSwitch(device) then
        device.profile.components["main"]:emit_event(ev)
    end

    device.profile.components[component_id]:emit_event(ev)
end

local component_to_endpoint = function(device, component_id)
    log.info("--------- Moon --------->> component_to_endpoint - component_id : ", component_id)
    local ep = component_id:match("switch(%d)")
    return ep and tonumber(ep) or device.fingerprinted_endpoint_id
end

-- It will not be called due to received_handler in zigbee_handlers
local endpoint_to_component = function(device, ep)
    log.info("--------- Moon --------->> endpoint_to_component - endpoint : ", ep)
    local component_id = string.format("switch%d", ep)
    return component_id
end

function syncComponent(device)
    local status = device:get_latest_state(getRemapSwitch(device), "switch", "switch", "off", nil)
    if status ~= nil then
        if status == "off" then
            device.profile.components["main"]:emit_event(capabilities.switch.switch.off())
        else
            device.profile.components["main"]:emit_event(capabilities.switch.switch.on())
        end
    end
end

local device_info_changed = function(driver, device, event, args)
    syncComponent(device)
end

local device_init = function(self, device)
    log.info("--------- Moon --------->> device_init")
    device:set_component_to_endpoint_fn(component_to_endpoint) -- get_endpoint_for_component_id
    device:set_endpoint_to_component_fn(endpoint_to_component)
end

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")
    -- Workaround : Should emit or send to enable capabilities UI
    for key, value in pairs(device.profile.components) do
        log.info("--------- Moon --------->> device_added - key : ", key)
        device.profile.components[key]:emit_event(capabilities.switch.switch.on())
        device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
    end
end

local device_driver_switched = function()
    getRemapSwitch(device)(device)
end

local function configure_device(self, device)
    device:configure()
end

local zigbee_tuya_switch_driver_template = {
    supported_capabilities = {
        capabilities.switch,
        capabilities.refresh
    },
    capability_handlers = {
        [capabilities.switch.ID] = {
            [capabilities.switch.commands.on.NAME] = on_handler,
            [capabilities.switch.commands.off.NAME] = off_handler
        }
    },
    zigbee_handlers = {
        attr = {
            [zcl_clusters.OnOff.ID] = {
                [zcl_clusters.OnOff.attributes.OnOff.ID] = received_handler
            }
        }
    },
    lifecycle_handlers = {
        infoChanged = device_info_changed,
        init = device_init,
        added = device_added,
        --driverSwitched = device_driver_switched,
        doConfigure = configure_device
    }
}

defaults.register_for_default_handlers(zigbee_tuya_switch_driver_template, zigbee_tuya_switch_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-switch", zigbee_tuya_switch_driver_template)
--local zigbee_driver = ZigbeeDriver("zigbee-tuya-switch-dev", zigbee_tuya_switch_driver_template)
zigbee_driver:run()