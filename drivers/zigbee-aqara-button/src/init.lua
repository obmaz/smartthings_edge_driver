-- Zigbee Aqara Button
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

local button_handler_WXKG11LM_original = function(driver, device, value, zb_rx)
  log.info("<<---- Moon ---->> button_handler_WXKG11LM", value.value)
  local component_id = "button1"
  local ev

  -- WXKG11LM (original revision) -> 01 : press, 02 : double-click, 03 : triple-click, 04 : quad-click
  local clickType = value.value
  if clickType == 1 then
    ev = capabilities.button.button.pushed()
  elseif clickType == 2 then
    ev = capabilities.button.button.double()
  elseif clickType == 3 then
    ev = capabilities.button.button.down_hold()
  elseif clickType == 4 then
    ev = capabilities.button.button.up_hold()
  end

  if ev ~= nil then
    ev.state_change = true
    device.profile.components[component_id]:emit_event(ev)
  end
end

local button_handler_WXKG12LM = function(driver, device, value, zb_rx)
  log.info("<<---- Moon ---->> button_handler_WXKG12LM", value.value)
  local component_id = "button1"
  local ev

  -- WXKG11LM (new revision) -> 0: hold (down_hold), 01 = click, 02 = double lick, 255 = hold_release (up_hold)
  -- WXKG12LM -> 01: click, 02: double click, 16: hold (down_hold), 17: hold_release (up_hold), 18: shake => pushed_6x
  local clickType = value.value
  if clickType == 1 then
    ev = capabilities.button.button.pushed()
  elseif clickType == 2 then
    ev = capabilities.button.button.double()
  elseif clickType == 16 or 0 then
    ev = capabilities.button.button.down_hold()
  elseif clickType == 17 or 255 then
    ev = capabilities.button.button.up_hold()
  elseif clickType == 18 then
    ev = capabilities.button.button.pushed_6x()
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
    device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "down_hold", "up_hold", "pushed_6x" }))
    device.profile.components[key]:emit_event(capabilities.button.button.pushed())
  end
end

local configure_device = function(self, device)
  device:configure()
end

local zigbee_aqara_button_driver_template = {
  supported_capabilities = {
    capabilities.button,
    capabilities.battery,
    capabilities.refresh
  },
  zigbee_handlers = {
    attr = {
      [0x0012] = {
        [0x0055] = button_handler_WXKG12LM
      },
      [0x0006] = {
        [0x0000] = button_handler_WXKG11LM_original
      },
    },
  },
  lifecycle_handlers = {
    added = device_added,
    doConfigure = configure_device,
  }
}
defaults.register_for_default_handlers(zigbee_aqara_button_driver_template, zigbee_aqara_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-aqara-button", zigbee_aqara_button_driver_template)
zigbee_driver:run()