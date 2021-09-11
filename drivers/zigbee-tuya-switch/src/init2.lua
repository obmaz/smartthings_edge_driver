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
    -- 최초 실행 안하면 ui에서 안나옴
    device.profile.components["main"]:emit_event(capabilities.switch.switch.on())
    device.profile.components["switch1"]:emit_event(capabilities.switch.switch.on())
    device.profile.components["switch2"]:emit_event(capabilities.switch.switch.on())
end

local function handle_on(driver, device, command)
    local endpoint = device:get_endpoint_for_component_id(command.component) -- nit 에서 등록한 component_to_endpoint 가 호출됨
    log.info("Send off command to device : handle_on endpoint", endpoint)
    device:send(zcl_clusters.OnOff.server.commands.On(device):to_endpoint(endpoint))
    device:emit_event_for_endpoint(endpoint,capabilities.switch.switch.attr,on())
end

local function handle_off(driver, device, command)
    local endpoint = device:get_endpoint_for_component_id(command.component) -- nit 에서 등록한 component_to_endpoint 가 호출됨
    log.info("Send off command to device : handle_off endpoint", endpoint)
    device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(endpoint))
    device:emit_event_for_endpoint(endpoint,capabilities.switch.switch.attr,off())
end

local function component_to_endpoint(device, component_id)
    log.info("--------- Moon --------->> component_to_endpoint component_id : ", component_id)

    if component_id == "switch1" then
        return 0x01
    else
        local ep_num = component_id:match("switch(%d)")
        log.info("--------- Moon --------->> component_to_endpoint ep_num : ", ep_num)
        return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
    end
end

local function endpoint_to_component(device, ep)
    log.info("--------- Moon --------->> endpoint_to_component : ", device.fingerprinted_endpoint_id)
    --if ep == device.fingerprinted_endpoint_id then
    --    log.info("--------- Moon --------->> endpoint_to_component : device.fingerprinted_endpoint_id == ep", ep)
    --    return "main"
    --end

    if ep == 1 then
        log.info("--------- Moon --------->> endpoint_to_component : device.fingerprinted_endpoint_id = 1", ep)
        return "switch1"
    end

    if ep == 2 then
        log.info("--------- Moon --------->> endpoint_to_component : device.fingerprinted_endpoint_id = 2", ep)
        return "switch2"
    end
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
local zigbee_driver = ZigbeeDriver("zigbee-tuya-switch", zigbee_tuya_switch_driver_template)
zigbee_driver:run()
