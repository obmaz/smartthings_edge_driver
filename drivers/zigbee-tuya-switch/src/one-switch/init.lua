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

--local on_handler = function(driver, device, command)
--  log.info("<<---- Moon ---->> on_handler - component : ", command.component)
--  device:emit_event(capabilities.switch.switch.on())
--  device:send(zcl_clusters.OnOff.server.commands.On(device))
--end
--
--local off_handler = function(driver, device, command)
--  log.info("<<---- Moon ---->> off_handler - component : ", command.component)
--  device:emit_event(capabilities.switch.switch.off())
--  device:send(zcl_clusters.OnOff.server.commands.Off(device))
--end

local on_off_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> on_off_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> on_off_handler - command.command : ", command.command)
  local ev = (command.command == "off") and capabilities.switch.switch.off() or capabilities.switch.switch.on()
  local OnOff = (command.command == "off") and zcl_clusters.OnOff.server.commands.Off(device) or zcl_clusters.OnOff.server.commands.On(device)
  device:emit_event(ev)
  device:send(OnOff)
end

local refresh_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> refresh_handler")
end

local device_added = function(driver, device)
  log.info("<<---- Moon ---->> device_added")
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
      log.info("<<---- Moon ---->> is_one_switch : true")
      return true
    end
  end

  log.info("<<---- Moon ---->> is_one_switch : false")
  return false
end

local zigbee_tuya_one_switch = {
  NAME = "zigbee tuya one switch",
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_off_handler, --on_handler,
      [capabilities.switch.commands.off.NAME] = on_off_handler, --off_handler,
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    }
  },
  lifecycle_handlers = {
    added = device_added,
    doConfigure = configure_device
  },
  can_handle = is_one_switch
}

return zigbee_tuya_one_switch