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

function button_handler (driver, device, value, zb_rx)
  log.info("<<---- Moon ---->> button_handler", value.value)
  --local ep = value.value
  local component_id = "button1" --string.format("button%d", ep)cd

  -- 01: click, 01: double click, 02: hold_release
  --local clickType = string.byte(value.value)
  --if clickType == 1 then
  --  local ev = capabilities.button.button.pushed()
  --  ev.state_change = true
  --  device.profile.components[component_id]:emit_event(ev)
  --end
  log.info("<<---- Moon ---->> button_handler 12uvgy")

  --if clickType == 11 then
  --  local ev = capabilities.button.button.double()
  --  ev.state_change = true
  --  device.profile.components[component_id]:emit_event(ev)
  --end
  --
  --if clickType == 12 then
  --  local ev = capabilities.button.button.held()
  --  ev.state_change = true
  --  device.profile.components[component_id]:emit_event(ev)
  --end
end

local device_added = function(driver, device)
  log.info("<<---- Moon ---->> device_added")

  for key, value in pairs(device.profile.components) do
    log.info("<<---- Moon ---->> device_added - component : ", key)
    device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
    device.profile.components[key]:emit_event(capabilities.button.button.pushed())
  end
end

local device_info_changed = function(driver, device, event, args)
  -- workaround : edge driver bug..sometime device lost own supported button
  for key, value in pairs(device.profile.components) do
    log.info("<<---- Moon ---->> device_added - component : ", key)
    device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
  end
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
        [0x0055] = button_handler
      },
    },
  },
  lifecycle_handlers = {
    added = device_added,
    infoChanged = device_info_changed,
  }
}
defaults.register_for_default_handlers(zigbee_aqara_button_driver_template, zigbee_aqara_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-aqara-button", zigbee_aqara_button_driver_template)
zigbee_driver:run()

-- 01 0104 5F01 01 04 0000 0012 0006 0001 01 0000

--<ZigbeeDevice: a79443c8-626b-4577-ada6-1d93a63f030f [0x1A4C] (Aqara 1 Button)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x1A4C,
--src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: 0x0012 >, lqi: 0xFF, rssi: -69, body_length: 0x0008, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x18, seqno: 0x00, ZCLCommandId: 0x0A >, < Repor
--tAttribute || < AttributeRecord || AttributeId: 0x0055, DataType: Uint16, Uint16: 0x0001 > > > >

--tuya
--<ZigbeeDevice: b3c58875-f796-46d6-b40e-2fd2c45c3e71 [0xE0EA] (Zigbee Tuya 3 Button)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x
--E0EA, src_endpoint: 0x02, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -61, body_length: 0x0004, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x53, ZCLCommandId: 0xFD >, Gen
--ericBody:  00 > >
