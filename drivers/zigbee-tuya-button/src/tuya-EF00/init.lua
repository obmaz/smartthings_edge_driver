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

local capabilities = require "st.capabilities"
local log = require "log"
local button_utils = require "tuya_button_utils"

local SUPPORTED_BUTTON_VALUES = { "pushed", "double", "held" }
local TUYA_EF00_CLUSTER_ID = 0xEF00

local button_handler = function(driver, device, zb_rx)
  local zcl_body = zb_rx and zb_rx.body and zb_rx.body.zcl_body or nil
  local body_bytes = zcl_body and zcl_body.body_bytes or nil
  if body_bytes == nil then
    log.warn("Ignoring malformed Tuya EF00 button message")
    return
  end

  -- https://drive.google.com/file/d/1WaoM80xPi2TMsf-Z-itKLr2p7VKFZ5xh/view
  -- maybe battery...
  -- to do: battery handling
  local button_number = button_utils.byte_at(body_bytes, 3)
  if button_number == 10 then
    -- This data point appears to contain battery data, but its format is not
    -- documented for all supported fingerprints.
    return
  end

  -- DTH
  -- buttonNumber = zigbee.convertHexToInt(descMap?.data[2])
  -- buttonState = zigbee.convertHexToInt(descMap?.data[6])
  -- Note: Groovy Array start 0, Lua Index start 1
  local component_id = button_utils.button_component_id(device, button_number)
  -- 00: click, 01: double click, 02: held
  local click_type = button_utils.byte_at(body_bytes, 7)
  button_utils.emit_state_change(device, component_id, button_utils.standard_button_event(click_type))
end

local device_added = function(driver, device)
  log.info("<<---- Moon ---->> EF00 / device_added")
  button_utils.initialize_button_components(device, SUPPORTED_BUTTON_VALUES)
end

local device_doconfigure = function(self, device)
  log.info("<<---- Moon ---->> EF00 / configure_device")
  -- EF00 remotes do not expose the PowerConfiguration cluster. Avoid the
  -- default bind/reporting configuration so the sleepy device can remain
  -- asleep between button events.
  -- Do not enable this for EF00 remotes.
  -- device:configure()
end

local is_tuya_ef00 = function(opts, driver, device)
  -- fingerprints.yaml selects this driver and the matching device profile.
  -- Select the sub-driver from the device's advertised cluster instead of
  -- duplicating every manufacturer/model fingerprint in Lua.
  return device:supports_server_cluster(TUYA_EF00_CLUSTER_ID)
end

local tuya_ef00 = {
  NAME = "tuya ef00",
  zigbee_handlers = {
    cluster = {
      -- No Attr Data from zb_rx, so it should use cluster handler
      [TUYA_EF00_CLUSTER_ID] = {
        -- ZCLCommandId
        [0x01] = button_handler
      },
    },
  },
  lifecycle_handlers = {
    added = device_added,
    doConfigure = device_doconfigure,
  },
  can_handle = is_tuya_ef00,
}

return tuya_ef00
