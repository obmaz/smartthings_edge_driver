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

local function get_ep_offset(device)
  return device.fingerprinted_endpoint_id - 1
end

local button_handler_EF00 = function(driver, device, zb_rx)
  log.info("<<---- Moon ---->> multi / button_handler zb_rx.body.zcl_body.body_bytes", zb_rx.body.zcl_body.body_bytes)
  -- https://drive.google.com/file/d/1WaoM80xPi2TMsf-Z-itKLr2p7VKFZ5xh/view
  -- maybe battery...
  -- to do: battery handling
  if zb_rx.body.zcl_body.body_bytes:byte(3) == 10 then
    return
  end
  -- DTH
  -- buttonNumber = zigbee.convertHexToInt(descMap?.data[2])
  -- buttonState = zigbee.convertHexToInt(descMap?.data[6])
  -- Note: Groovy Array start 0, Lua Index start 1

  local component_id = string.format("button%d", zb_rx.body.zcl_body.body_bytes:byte(3))
  log.info("<<---- Moon ---->> multi / button_handler component_id", component_id)

  -- 00: click, 01: double click, 02: held
  local clickType = zb_rx.body.zcl_body.body_bytes:byte(7)
  local ev
  log.info("<<---- Moon ---->> multi / button_handler clickType", clickType)
  if clickType == 0 then
    log.info("<<---- Moon ---->> multi / button_handler clickType-0")
    ev = capabilities.button.button.pushed()
  elseif clickType == 1 then
    log.info("<<---- Moon ---->> multi / button_handler clickType-1")
    ev = capabilities.button.button.double()
  elseif clickType == 2 then
    log.info("<<---- Moon ---->> multi / button_handler clickType-2")
    ev = capabilities.button.button.held()
  end

  if ev ~= nil then
    ev.state_change = true
    device.profile.components[component_id]:emit_event(ev)
  end
end

local device_added = function(driver, device)
  log.info("<<---- Moon ---->> multi / device_added")

  for key, value in pairs(device.profile.components) do
    log.info("<<---- Moon ---->> multi / device_added - component : ", key)
    device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
    device.profile.components[key]:emit_event(capabilities.button.button.pushed())
  end
end

local device_doconfigure = function(self, device)
  log.info("<<---- Moon ---->> multi / configure_device")
  -- todo: need to bind monitored attribute since this device don't have 0001 cluster
  -- so there might be no default reporting cluster. It can cause health check fail or button might need to wake up
  device:configure()
end

local ZIGBEE_TUYA_BUTTON_EF00_FINGERPRINTS = {
  { mfr = "_TZE200_zqtiam4u", model = "TS0601" },
  { mfr = "_TZE204_mpg22jc1", model = "TS0601" },
  { mfr = "_TZ3210_3ulg9kpo", model = "TS0021" },
}

local is_tuya_ef00 = function(opts, driver, device)
  for _, fingerprint in ipairs(ZIGBEE_TUYA_BUTTON_EF00_FINGERPRINTS) do
    log.info("<<---- Moon ---->> is_tuya_ef00 :", device:pretty_print())

    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      log.info("<<---- Moon ---->> is_tuya_ef00 : true / device.fingerprinted_endpoint_id :", device.fingerprinted_endpoint_id)
      return true
    end
  end

  log.info("<<---- Moon ---->> is_tuya_ef00 : false")
  return false
end

local tuya_ef00 = {
  NAME = "tuya ef00",
  zigbee_handlers = {
    cluster = {
      -- No Attr Data from zb_rx, so it should use cluster handler
      [0xEF00] = {
        -- ZCLCommandId
        [0x01] = button_handler_EF00
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