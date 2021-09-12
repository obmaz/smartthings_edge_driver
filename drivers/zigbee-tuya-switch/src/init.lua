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

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")
    -- 최초 실행 안하면 ui에서 안나옴
    for key,value in pairs(device.profile.components) do
        log.info("--------- Moon --------->> device_added - component : ", key)
        device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
    end
end

local function handle_on(driver, device, command)
    log.info("--------- Moon --------->> handle_on - component : ", command.component)
    device.profile.components[command.component]:emit_event(capabilities.switch.switch.on())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.On(device))
end

local function handle_off(driver, device, command)
    log.info("--------- Moon --------->> handle_off - component : ", command.component)
    --아래와 같이 endpoint를 구해서 호출도 가능, endpoint 값 조작이 필요할 경우 사용
    --local endpoint = device:get_endpoint_for_component_id(command.component)
    --device:emit_event_for_endpoint(endpoint, capabilities.switch.switch.off())
    --device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(endpoint))
    device.profile.components[command.component]:emit_event(capabilities.switch.switch.off())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.Off(device))
end

local function component_to_endpoint(device, component_id)
    log.info("--------- Moon --------->> component_to_endpoint - component_id : ", component_id)
    if component_id == "main" then
        return device.fingerprinted_endpoint_id
    else
        local ep_num = component_id:match("switch(%d)")
        return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
    end
end

local function endpoint_to_component(device, ep)
    log.info("--------- Moon --------->> endpoint_to_component - endpoint : ", ep)
    if ep == device.fingerprinted_endpoint_id then
        return "main"
    else
        return string.format("switch%d", ep)
    end
end

local device_init = function(self, device)
    log.info("--------- Moon --------->> device_init")
    device:set_component_to_endpoint_fn(component_to_endpoint) -- ??? get_endpoint_for_component_id 하면 component_to_endpoint 가 호출 됨 ???
    device:set_endpoint_to_component_fn(endpoint_to_component) -- 물리 버튼에서 신호가 오면 component_to_endpoint 가 호출 됨
end

local zigbee_tuya_switch_driver_template = {
    supported_capabilities = {
        capabilities.switch,
        capabilities.refresh
    },
    -- UI를 누를때 호출
    capability_handlers = {
        [capabilities.switch.ID] = {
            [capabilities.switch.commands.on.NAME] = handle_on,
            [capabilities.switch.commands.off.NAME] = handle_off
        }
    },
    lifecycle_handlers = {
        added = device_added,
        init = device_init,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_switch_driver_template, zigbee_tuya_switch_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-switch", zigbee_tuya_switch_driver_template)
zigbee_driver:run()