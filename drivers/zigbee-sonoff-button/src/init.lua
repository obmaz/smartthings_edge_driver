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
local zcl_clusters = require "st.zigbee.zcl.clusters"

--function button_handler(driver, device, zb_rx)
--end
function button_handler (driver, device, value, zb_rx)
  log.info("<<---- Moon ---->> button_handler", value.value)
  local component_id = "button1"
  local ev

  ---- 01: click, 02: double click, 16: hold (down_hold), 17: hold_release (up_hold), 18: shake => pushed_6x
  --local clickType = value.value
  --if clickType == 1 then
  --  ev = capabilities.button.button.pushed()
  --elseif clickType == 2 then
  --  ev = capabilities.button.button.double()
  --elseif clickType == 16 then
  --  ev = capabilities.button.button.down_hold()
  --elseif clickType == 17 then
  --  ev = capabilities.button.button.up_hold()
  --elseif clickType == 18 then
  --  ev = capabilities.button.button.pushed_6x()
  --end
  --ev.state_change = true
  --device.profile.components[component_id]:emit_event(ev)
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
  device:send(device_management.build_bind_request(device, 0x02, device.driver.environment_info.hub_zigbee_eui))
end

local zigbee_sonoff_button_driver_template = {
  supported_capabilities = {
    capabilities.button,
    capabilities.battery,
    capabilities.refresh
  },

  --inClusters: "0000, 0001, 0003", outClusters: "0003, 0006
  -- 	01 0104 0000 00 03 0000 0003 0001 02 0006 0003
  -- ep, profile,
  --https://github.com/pablopoo/smartthings/blob/master/Sonoff-Zigbee-Button.groovy
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
    doConfigure = do_configure,
  }
}

function attr_handler(driver, device, value, zb_rx)
  log.info("<<---- Moon ---->> attr_handler")

end

defaults.register_for_default_handlers(zigbee_sonoff_button_driver_template, zigbee_sonoff_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-sonoff-button", zigbee_sonoff_button_driver_template)
zigbee_driver:run()

--    <ZigbeeDevice: f16b75ed-d764-4bfb-84d3-c466ec5e056f [0x6D99] (SONOFF SNZB-01)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0x6D99,
--src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -32, body_length: 0x0003, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x02, ZCLCommandId: 0x02 >, < Toggle
--||  > > >

--attr:
--ZclClusterAttributeValueHandler: cluster: PowerConfiguration, attribute: BatteryVoltage
--ZclClusterAttributeValueHandler: cluster: PowerConfiguration, attribute: BatteryPercentageRemaining
--global:
--cluster:
--ZclClusterCommandHandler: cluster: OnOff, command: On
--ZclClusterCommandHandler: cluster: OnOff, command: Toggle
--ZclClusterCommandHandler: cluster: OnOff, command: Off


-- tuya
--    <ZigbeeDevice: b3c58875-f796-46d6-b40e-2fd2c45c3e71 [0xE0EA] (커튼 리모콘)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0xE0EA, src
--_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -32, body_length: 0x0004, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x7D, ZCLCommandId: 0xFD >, GenericBody:
--00 > >
