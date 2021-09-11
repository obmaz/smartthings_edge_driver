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

local comp = { "button1", "button2", "button3", "button4" }

local device_added = function(driver, device)
    log.info("--------- Moon --------->> device_added")
    -- 최초 실행 안하면 ui에서 안나옴
    device.profile.components["main"]:emit_event(capabilities.switch.switch.on())
    --device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(endpoint))
    device.profile.components["switch1"]:emit_event(capabilities.switch.switch.on())
    device.profile.components["switch2"]:emit_event(capabilities.switch.switch.on())
end

local function handle_on(driver, device, command)
    log.info("handle_on component : ", command.component)
    device:emit_event_for_endpoint(endpoint, capabilities.switch.switch.on())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.On(device))
end

local function handle_off(driver, device, command)
    log.info("handle_off component : ", command.component)
    device:emit_event_for_endpoint(endpoint, capabilities.switch.switch.off())
    device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.Off(device))
    -- Note : "send_to_component" 는 아래의 코드를 수행하는것 같음
    -- local endpoint = device:get_endpoint_for_component_id(command.component)
    -- device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(endpoint))
end

local function component_to_endpoint(device, component_id)
    local ep_num = component_id:match("switch(%d)")
    log.info("--------- Moon --------->> component_to_endpoint ep_num : ", ep_num)
    return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
end

local function endpoint_to_component(device, ep)
    log.info("--------- Moon --------->> endpoint_to_component : ", device.fingerprinted_endpoint_id)
    return string.format("switch%d", ep)
end

local device_init = function(self, device)
    log.info("--------- Moon --------->> device_init")
    device:set_component_to_endpoint_fn(component_to_endpoint) -- get_endpoint_for_component_id 하면 component_to_endpoint 가 호출 됨
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
        --doConfigure = configure_device,
        init = device_init,
    }
}

defaults.register_for_default_handlers(zigbee_tuya_switch_driver_template, zigbee_tuya_switch_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-switch-temp", zigbee_tuya_switch_driver_template)
zigbee_driver:run()
