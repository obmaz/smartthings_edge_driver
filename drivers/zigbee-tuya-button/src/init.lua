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

local refresh_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> refresh_handler")
  -- device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
  -- it does not need since device:refresh() call binding cluster (PowerConfiguration == 0x0001)
  device:refresh()
end

local button_handler_Knob_Scene_Toggle = function(driver, device, zb_rx)
  -- Note: Scene mode knob up/down send "Step" command, but it is not a zigbee standard. Toggle is a standard
  -- st cluster library does not implement it, so I cannot catch the 'Step' in cluster handler

  -- log
  -- Missing command arg options_mask for deserializing Step
  -- <ZigbeeDevice: 74ee34cc-5c5d-49d3-b4a8-a39f5fa2a13a [0x6423] (Tuya Knob)> received Zigbee message: < ZigbeeMessageRx || type: 0x01, < AddressHeader || src_addr: 0x4408, src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0xFF, profile: 0x0104, cluster: OnOff >, lqi: 0xFF, rssi: -61, body_length: 0x0003, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0x26, ZCLCommandId: 0x02 >, < Toggle ||  > > >
  -- <ZigbeeDevice: 74ee34cc-5c5d-49d3-b4a8-a39f5fa2a13a [0x6423] (Tuya Knob)> received Zigbee message: < ZigbeeMessageRx || type: 0x01, < AddressHeader || src_addr: 0x6423, src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0xFF, profile: 0x0104, cluster: Level >, lqi: 0xFF, rssi: -58, body_length: 0x0007, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x01, seqno: 0xCE, ZCLCommandId: 0x02 >, < Step || MoveStepMode: UP, step_size: 0x49, transition_time: 0x0002 > > >

  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> button_handler_Knob_Scene_Toggle", ep)

  local number = ep - get_ep_offset(device)
  local component_id = string.format("button%d", number)
  local ev = capabilities.button.button.pushed()
  ev.state_change = true
  device.profile.components[component_id]:emit_event(ev)
end

local button_handler_Knob_Remote = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> button_handler_Knob_Remote", ep)

  local number = ep - get_ep_offset(device)
  local component_id = string.format("button%d", number)
  local ev

  -- 00: Clockwise, 01: Count Clockwise
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)" -- it will return decimal value
  local clickType = string.byte(zb_rx.body.zcl_body.body_bytes)
  if clickType == 0 then
    ev = capabilities.button.button.up()
  elseif clickType == 1 then
    ev = capabilities.button.button.down()
  end

  if ev ~= nil then
    ev.state_change = true
    device.profile.components[component_id]:emit_event(ev)
  end
end

local button_handler = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> button_handler", ep)

  local number = ep - get_ep_offset(device)
  local component_id = string.format("button%d", number)
  local ev

  -- 00: click, 01: double click, 02: held
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)" -- it will return decimal value
  local clickType = string.byte(zb_rx.body.zcl_body.body_bytes)
  if clickType == 0 then
    ev = capabilities.button.button.pushed()
  elseif clickType == 1 then
    ev = capabilities.button.button.double()
  elseif clickType == 2 then
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

    -- knob manufacturer check
    if device:get_manufacturer() == "_TZ3000_402vrq2i" then
      log.info("<<---- Moon ---->> is knob : true ")
      device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held", "up", "down" }))
    else
      log.info("<<---- Moon ---->> is knob : false ")
      device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held" }))
    end
    device.profile.components[key]:emit_event(capabilities.button.button.pushed())
  end
end

local configure_device = function(self, device)
  log.info("<<---- Moon ---->> configure_device")
  device:configure()
  device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
  -- some devices may leak battery drain
  -- device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:configure_reporting(device, 30, 21600, 1))
end

local zigbee_tuya_button_driver_template = {
  supported_capabilities = {
    capabilities.button,
    capabilities.battery,
    capabilities.refresh
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    }
  },
  zigbee_handlers = {
    cluster = {
      -- No Attr Data from zb_rx, so it should use cluster handler
      [zcl_clusters.OnOff.ID] = {
        -- ZCLCommandId
        [0x02] = button_handler_Knob_Scene_Toggle,
        [0xFC] = button_handler_Knob_Remote,
        [0xFD] = button_handler
      }
    },
  },
  lifecycle_handlers = {
    added = device_added,
    doConfigure = configure_device,
  },
  sub_drivers = {
    require("tuya-EF00")
  }
}

defaults.register_for_default_handlers(zigbee_tuya_button_driver_template, zigbee_tuya_button_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-button", zigbee_tuya_button_driver_template)
zigbee_driver:run()

-- Reported PowerConfiguration
-- <ZigbeeDevice: b3c58875-f796-46d6-b40e-2fd2c45c3e71 [0xE0EA] (커튼 리모콘)> received Zigbee message: < ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0xE0EA, src
--_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: PowerConfiguration >, lqi: 0xFF, rssi: -53, body_length: 0x0007, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x08, seqno: 0x17, ZCLCommandId: 0x0A >,
--< ReportAttribute || < AttributeRecord || AttributeId: 0x0021, DataType: Uint8, BatteryPercentageRemaining: 0xAE > > > >

-- Read PowerConfiguration, there is no BatteryPercentageRemaining value
-- <ZigbeeDevice: 1505117e-d370-46fc-ada4-1ac623dd5bdc [0xFFF7] (Zigbee Tuya 2 Button)> sending Zigbee message: < ZigbeeMessageTx || Uint16: 0x0000, < AddressHeader || src_addr:
--0x0000, src_endpoint: 0x01, dest_addr: 0xFFF7, dest_endpoint: 0x01, profile: 0x0104, cluster: PowerConfiguration >, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x00, seqno: 0x00, ZCLCommandId: 0x00 >, < ReadAttribute || AttributeId
--: 0x0021 > > >