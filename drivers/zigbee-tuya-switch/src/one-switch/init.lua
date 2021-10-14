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
local zcl_clusters = require "st.zigbee.zcl.clusters"

local on_handler = function(driver, device, command)
  log.info("--------- Moon --------->> on_handler - component : ", command.component)
  --device.profile.components[command.component]:emit_event(capabilities.switch.switch.on())
  --device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.On(device))
  device:emit_event(capabilities.switch.switch.on())
  device:send(zcl_clusters.OnOff.server.commands.On(device))
end

local off_handler = function(driver, device, command)
  log.info("--------- Moon --------->> off_handler - component : ", command.component)
  --device.profile.components[command.component]:emit_event(capabilities.switch.switch.off())
  --device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.Off(device))
  device:emit_event(capabilities.switch.switch.off())
  device:send(zcl_clusters.OnOff.server.commands.Off(device))
end

--local component_to_endpoint = function(device, component_id)
--  log.info("--------- Moon --------->> component_to_endpoint - component_id : ", component_id)
--  return device.fingerprinted_endpoint_id
--end
--
--local endpoint_to_component = function(device, ep)
--  log.info("--------- Moon --------->> endpoint_to_component - endpoint : ", ep)
--  return "main"
--end

--local device_init = function(self, device)
--  log.info("--------- Moon --------->> device_init")
--  device:set_component_to_endpoint_fn(component_to_endpoint)
--  device:set_endpoint_to_component_fn(endpoint_to_component)
--end

local device_added = function(driver, device)
  log.info("--------- Moon --------->> device_added")
  device.profile.components["main"]:emit_event(capabilities.switch.switch.on())
  device:send_to_component("main", zcl_clusters.OnOff.server.commands.On(device))
end

local function configure_device(self, device)
  device:configure()
end

local ZIGBEE_TUYA_SWITCH_FINGERPRINTS = {
  { mfr = "_TZ3000_oysiif07", model = "TS0001" }
}

local is_one_switch = function(opts, driver, device)
  for _, fingerprint in ipairs(ZIGBEE_TUYA_SWITCH_FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      log.info("--------- Moon --------->> is_one_switch : true")
      return true
    end
  end

  log.info("--------- Moon --------->> is_one_switch : false")
  return false
end

local zigbee_tuya_one_switch = {
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_handler,
      [capabilities.switch.commands.off.NAME] = off_handler
    }
  },
  lifecycle_handlers = {
    --init = device_init,
    added = device_added,
    doConfigure = configure_device
  },
  can_handle = is_one_switch
}

return zigbee_tuya_one_switch