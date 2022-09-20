-- Zigbee Sonoff Button
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

local button_handler = function(driver, device, zb_rx)
  log.info("<<---- Moon ---->> button_handler", zb_rx)
  local component_id = "button1"
  local ev
  -- see zb_rx : st.zigbee.device
  local clickType = zb_rx.body.zcl_header.cmd.value
  ---- 02: pushed, 01: double, 0: held
  if clickType == 2 then
    ev = capabilities.button.button.pushed()
  elseif clickType == 1 then
    ev = capabilities.button.button.double()
  elseif clickType == 0 then
    ev = capabilities.button.button.held()
  end

  if ev ~= nil then
    ev.state_change = true
    device.profile.components[component_id]:emit_event(ev)
  end
end

local device_added = function(driver, device)
  log.info("<<---- Moon ---->> device_added")

  for key, value in pairs(device.profile.components) do
    log.info("<<---- Moon ---->> device_added - component : ", key)
    device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
    device.profile.components[key]:emit_event(capabilities.button.button.pushed())
  end
end

local device_doconfigure = function(self, device)
  log.info("<<---- Moon ---->> configure_device")
  device:configure()
  device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
  device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:configure_reporting(device, 30, 21600, 1))
  -- FP : 01 0104 0000 00 03 0000 0003 0001 02 0006 0003
  -- it bind 0x0006 (OnOff cluster) manually due to no 0x0006 in FP
  device:send(device_management.build_bind_request(device, 0x0006, device.driver.environment_info.hub_zigbee_eui))
end

local zigbee_sonoff_button_driver_template = {
  supported_capabilities = {
    capabilities.button,
    capabilities.battery,
    capabilities.refresh
  },
  zigbee_handlers = {
    cluster = {
      -- No Attr Data from zb_rx, so it should use cluster handler
      [zcl_clusters.OnOff.ID] = {
        -- ZCLCommandId
        [0x00] = button_handler,
        [0x01] = button_handler,
        [0x02] = button_handler
      }
    },
  },
  lifecycle_handlers = {
    added = device_added,
    doConfigure = device_doconfigure,
  }
}

function attr_handler(driver, device, value, zb_rx)
  log.info("<<---- Moon ---->> attr_handler")

end

defaults.register_for_default_handlers(zigbee_sonoff_button_driver_template, zigbee_sonoff_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-sonoff-button", zigbee_sonoff_button_driver_template)
zigbee_driver:run()