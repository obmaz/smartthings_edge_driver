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

function button_handler2(driver, device, zb_rx)
  -- Temp Log
  log.info("<<---- Moon ---->> button_handler zb_rx.body.zcl_body.body_bytes", zb_rx.body.zcl_body.body_bytes)
  log.info("<<---- Moon ---->> button_handler zb_rx.body.zcl_body.body_bytes:byte(1)", zb_rx.body.zcl_body.body_bytes:byte(1))
  log.info("<<---- Moon ---->> button_handler zb_rx.body.zcl_body.body_bytes:byte(2)", zb_rx.body.zcl_body.body_bytes:byte(2))
  log.info("<<---- Moon ---->> button_handler zb_rx.body.zcl_body.body_bytes:byte(3)", zb_rx.body.zcl_body.body_bytes:byte(3))
  log.info("<<---- Moon ---->> button_handler zb_rx.body.zcl_body.body_bytes:byte(4)", zb_rx.body.zcl_body.body_bytes:byte(4))
  log.info("<<---- Moon ---->> button_handler zb_rx.body.zcl_body.body_bytes:byte(5)", zb_rx.body.zcl_body.body_bytes:byte(5))
  log.info("<<---- Moon ---->> button_handler zb_rx.body.zcl_body.body_bytes:byte(6)", zb_rx.body.zcl_body.body_bytes:byte(6))
  log.info("<<---- Moon ---->> button_handler zb_rx.body.zcl_body.body_bytes:byte(7)", zb_rx.body.zcl_body.body_bytes:byte(7))

  -- DTH
  -- buttonNumber = zigbee.convertHexToInt(descMap?.data[2])
  -- buttonState = zigbee.convertHexToInt(descMap?.data[6])
  -- Note: Groovy Array start 0, Lua Index start 1

  local component_id = string.format("button%d", zb_rx.body.zcl_body.body_bytes:byte(3))
  log.info("<<---- Moon ---->> button_handler component_id", component_id)

  -- 00: click, 01: double click, 02: held
  local clickType = zb_rx.body.zcl_body.body_bytes:byte(7)
  local ev
  log.info("<<---- Moon ---->> button_handler clickType", clickType)
  if clickType == 0 then
    log.info("<<---- Moon ---->> button_handler clickType-0")
    ev = capabilities.button.button.pushed()
  elseif clickType == 1 then
    log.info("<<---- Moon ---->> button_handler clickType-1")
    ev = capabilities.button.button.double()
  elseif clickType == 2 then
    log.info("<<---- Moon ---->> button_handler clickType-2")
    ev = capabilities.button.button.held()
  end
  ev.state_change = true
  device.profile.components[component_id]:emit_event(ev)
end

function button_handler(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> button_handler", ep)

  local number = ep - get_ep_offset(device)
  local component_id = string.format("button%d", number)
  local ev

  -- 00: click, 01: double click, 02: held
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)"
  local clickType = string.byte(zb_rx.body.zcl_body.body_bytes)
  if clickType == 0 then
    ev = capabilities.button.button.pushed()
  elseif clickType == 1 then
    ev = capabilities.button.button.double()
  elseif clickType == 2 then
    ev = capabilities.button.button.held()
  end
  ev.state_change = true
  device.profile.components[component_id]:emit_event(ev)
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
  --device:send(clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
  device:send(clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:configure_reporting(device, 30, 21600, 1))
end

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
        [0xFD] = button_handler,
      },
      [0xEF00] = {
        -- ZCLCommandId
        [0x01] = button_handler2
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