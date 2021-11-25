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
  log.info("<<---- Moon ---->> button_handler")

  local ep = zb_rx.address_header.src_endpoint.value
  -- ToDo: Check logic when end_point is not 0x01
  local component_id = string.format("button%d", ep)

  -- 00: click, 01: double click, 02: held
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
  log.info("<<---- Moon ---->> device_added")

  for key, value in pairs(device.profile.components) do
    log.info("<<---- Moon ---->> device_added - component : ", key)
    device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
    device.profile.components[key]:emit_event(capabilities.button.button.pushed())
  end
end

local do_configure = function(self, device)
  device:configure()
  device:send(clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
end

--local device_info_changed = function(driver, device, event, args)
--  -- workaround : edge driver bug..sometime device lost own supported button
--  --for key, value in pairs(device.profile.components) do
--  --  log.info("<<---- Moon ---->> device_added - component : ", key)
--  --  device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "down_hold", "up_hold", "pushed_6x" }))
--  --end
--end

local zigbee_tuya_button_driver_template = {
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
        [0xFD] = button_handler
      }
    },
  },
  lifecycle_handlers = {
    added = device_added,
    doConfigure = do_configure,
  }
}

defaults.register_for_default_handlers(zigbee_tuya_button_driver_template, zigbee_tuya_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-button", zigbee_tuya_button_driver_template)
zigbee_driver:run()