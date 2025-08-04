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

local knob_models = {
  ["_TZ3000_402vrq2i"] = true,
  ["_TZ3000_abrsvsou"] = true,
  ["_TZ3000_4fjiwweb"] = true,
  ["_TZ3000_gwkzibhs"] = true,
  ["_TZ3000_qja6nq5z"] = true
}

local function get_ep_offset(device)
  return device.fingerprinted_endpoint_id - 1
end

local refresh_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> refresh_handler")
  -- device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
  -- it does not need since device:refresh() call binding cluster (PowerConfiguration == 0x0001)
  device:refresh()
end

local button_handler_Knob_Scene_Wheel = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> button_handler_Knob_Scene_Wheel", ep)

  local number = ep - get_ep_offset(device)
  local component_button_id = string.format("button%d", number)
  local component_id = "wheel"
  local ev1
  local ev2

  -- {address_header={cluster={byte_length=2, field_name="cluster", value=8}, dest_addr={byte_length=2, field_name="dest_addr", value=0}, dest_endpoint={byte_length=1, field_name="dest_endpoint", value=255}, profile={byte_length=2, field_name="profile", value=260}, src_addr={byte_length=2, field_name="src_addr", value=57037}, src_endpoint={byte_length=1, field_name="src_endpoint", value=1}}, body={zcl_body={step_mode={byte_length=1, field_name="step_mode", value=0}, step_size={byte_length=1, field_name="step_size", value=85}, transition_time={byte_length=2, field_name="transition_time", value=3}}, zcl_header={cmd={byte_length=1, value=2}, frame_ctrl={byte_length=1, field_name="frame_ctrl", value=1}, seqno={byte_length=1, field_name="seqno", value=54}}}, body_length={byte_length=2, field_name="body_length", value=7}, lqi={byte_length=1, field_name="lqi", value=255}, rssi={byte_length=1, field_name="rssi", value=-33}, type={byte_length=1, field_name="type", value=1}}
  -- 48: Clockwise, 49: Count Clockwise
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)" -- it will return decimal value
  local clickType = string.byte(zb_rx.body.zcl_body.step_mode.value)
  local stepSizeValue = math.floor((zb_rx.body.zcl_body.step_size.value / 255) * 50 + 50 + 0.5)
  log.info("<<---- Moon ---->> button_handler_Knob_Scene_Wheel_clickType", clickType)
  log.info("<<---- Moon ---->> button_handler_Knob_Scene_Wheel_value", stepSizeValue)

  if clickType == 48 then
    ev1 = capabilities.switchLevel.level({ value = stepSizeValue })
    ev2 = capabilities.button.button.up()

  elseif clickType == 49 then
    stepSizeValue = 100 - stepSizeValue
    ev1 = capabilities.switchLevel.level({ value = stepSizeValue })
    ev2 = capabilities.button.button.down()
  end

  if ev1 ~= nil then
    ev1.state_change = true
    ev2.state_change = true
    device.profile.components[component_id]:emit_event(ev1)
    device.profile.components[component_button_id]:emit_event(ev2)
  end
end

local button_handler_Knob_Scene_Hold_Wheel = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> button_handler_Knob_Scene_Hold_Wheel", ep)

  local number = ep - get_ep_offset(device)
  local component_button_id = string.format("button%d", number)
  local component_id = "hold_wheel"
  local ev1
  local ev2

  -- 00: Clockwise, 01: Count Clockwise
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)" -- it will return decimal value
  local clickType = string.byte(zb_rx.body.zcl_body.step_mode.value)
  local stepSizeValue = math.floor((zb_rx.body.zcl_body.step_size.value / 255) * 50 + 50 + 0.5)
  log.info("<<---- Moon ---->> button_handler_Knob_Scene_Hold_Wheel_clickType", clickType)
  log.info("<<---- Moon ---->> button_handler_Knob_Scene_Hold_Wheel_value", stepSizeValue)

  if clickType == 49 then
    ev1 = capabilities.switchLevel.level({ value = stepSizeValue })
    ev2 = capabilities.button.button.up_hold()

  elseif clickType == 51 then
    stepSizeValue = 100 - stepSizeValue
    ev1 = capabilities.switchLevel.level({ value = stepSizeValue })
    ev2 = capabilities.button.button.down_hold()
  end

  if ev1 ~= nil then
    ev1.state_change = true
    ev2.state_change = true
    device.profile.components[component_id]:emit_event(ev1)
    device.profile.components[component_button_id]:emit_event(ev2)
  end
end

local button_handler_Knob_Scene_Toggle = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> button_handler_Knob_Scene_Toggle", ep)

  -- For the regular TS004F (not the knob version), both remote and scene signals are sent simultaneously, so defensive code needs to be implemented.
  local manufacturer = device:get_manufacturer()
  if knob_models[manufacturer] then
    log.info("<<---- Moon ---->> is knob : true ")
    local number = ep - get_ep_offset(device)
    local component_id = string.format("button%d", number)
    local ev = capabilities.button.button.pushed()
    ev.state_change = true
    device.profile.components[component_id]:emit_event(ev)
  else
    log.info("<<---- Moon ---->> is knob : false ")
  end
end

local button_handler_Knob_Remote_Wheel = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> button_handler_Knob_Remote_wheel", ep)

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
  device:send(zcl_clusters.Groups.server.commands.RemoveAllGroups(device))
  log.info("<<---- Moon ---->> device_removed_from_all_group")

  for key, value in pairs(device.profile.components) do
    log.info("<<---- Moon ---->> device_added - component : ", key)

    -- knob manufacturer check
    local manufacturer = device:get_manufacturer()
    if knob_models[manufacturer] then
      log.info("<<---- Moon ---->> is knob : true ")
      device.profile.components[key]:emit_event(capabilities.button.supportedButtonValues({ "pushed", "double", "held", "up", "down", "up_hold", "down_hold" }))
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
        [0xFC] = button_handler_Knob_Remote_Wheel,
        [0xFD] = button_handler
      },
      [zcl_clusters.Level.ID] = {
        -- ZCLCommandId
        [0x02] = button_handler_Knob_Scene_Wheel
      },
      [zcl_clusters.ColorControl.ID] = {
        -- ZCLCommandId
        [0x4C] = button_handler_Knob_Scene_Hold_Wheel
      },
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
