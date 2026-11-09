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
local defaults = require "st.zigbee.defaults"
local log = require "log"
local ZigbeeDriver = require "st.zigbee"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local button_utils = require "tuya_button_utils"

local KNOB_MANUFACTURERS = {
  ["_TZ3000_402vrq2i"] = true,
  ["_TZ3000_abrsvsou"] = true,
  ["_TZ3000_4fjiwweb"] = true,
  ["_TZ3000_gwkzibhs"] = true,
  ["_TZ3000_1fqpj6qz"] = true,
  ["_TZ3000_qja6nq5z"] = true
}

local STANDARD_BUTTON_VALUES = { "pushed", "double", "held" }
local KNOB_BUTTON_VALUES = { "pushed", "double", "held", "up", "down", "up_hold", "down_hold" }

local PowerConfiguration = zcl_clusters.PowerConfiguration

local function is_knob(device)
  return KNOB_MANUFACTURERS[device:get_manufacturer()] == true
end

local function get_zcl_body(zb_rx)
  return zb_rx and zb_rx.body and zb_rx.body.zcl_body or nil
end

local function wheel_level(step_size)
  if step_size == nil then
    return nil
  end
  local clamped_step_size = math.max(0, math.min(255, step_size))
  return math.floor((clamped_step_size / 255) * 50 + 50 + 0.5)
end

local refresh_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> refresh_handler")
  -- Original implementation note kept for device-specific history:
  -- device:send(zcl_clusters.PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
  -- it does not need since device:refresh() call binding cluster (PowerConfiguration == 0x0001)
  -- The explicit one-shot read is now used instead of device:refresh() so the
  -- default refresh path cannot introduce PowerConfiguration reporting.
  if device:supports_server_cluster(PowerConfiguration.ID) then
    device:send(PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
  end
end

local knob_scene_wheel_handler = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  local component_id = button_utils.button_component_id_for_endpoint(device, ep)
  local zcl_body = get_zcl_body(zb_rx)
  if component_id == nil or zcl_body == nil then
    return
  end

  -- Captured scene-mode Level cluster packet:
  -- {address_header={cluster={byte_length=2, field_name="cluster", value=8}, dest_addr={byte_length=2, field_name="dest_addr", value=0}, dest_endpoint={byte_length=1, field_name="dest_endpoint", value=255}, profile={byte_length=2, field_name="profile", value=260}, src_addr={byte_length=2, field_name="src_addr", value=57037}, src_endpoint={byte_length=1, field_name="src_endpoint", value=1}}, body={zcl_body={step_mode={byte_length=1, field_name="step_mode", value=0}, step_size={byte_length=1, field_name="step_size", value=85}, transition_time={byte_length=2, field_name="transition_time", value=3}}, zcl_header={cmd={byte_length=1, value=2}, frame_ctrl={byte_length=1, field_name="frame_ctrl", value=1}, seqno={byte_length=1, field_name="seqno", value=54}}}, body_length={byte_length=2, field_name="body_length", value=7}, lqi={byte_length=1, field_name="lqi", value=255}, rssi={byte_length=1, field_name="rssi", value=-33}, type={byte_length=1, field_name="type", value=1}}
  -- 48: Clockwise, 49: Count Clockwise
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)" -- it will return decimal value
  -- normalized_digit accepts both the ASCII values above and numeric 0/1.
  local direction = button_utils.normalized_digit(zcl_body.step_mode)
  local level = wheel_level(button_utils.numeric_value(zcl_body.step_size))
  local level_event
  local button_event

  if direction == 0 and level ~= nil then
    level_event = capabilities.switchLevel.level({ value = level })
    button_event = capabilities.button.button.up()
  elseif direction == 1 and level ~= nil then
    level_event = capabilities.switchLevel.level({ value = 100 - level })
    button_event = capabilities.button.button.down()
  end

  if level_event ~= nil then
    button_utils.emit_state_change(device, "wheel", level_event)
    button_utils.emit_state_change(device, component_id, button_event)
  end
end

local knob_scene_hold_wheel_handler = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  local component_id = button_utils.button_component_id_for_endpoint(device, ep)
  local zcl_body = get_zcl_body(zb_rx)
  if component_id == nil or zcl_body == nil then
    return
  end

  -- 00: Clockwise, 01: Count Clockwise
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)" -- it will return decimal value
  -- Captured hold-wheel commands use values 49/51 (ASCII "1"/"3");
  -- normalized_digit converts them to 1/3 before matching below.
  local direction = button_utils.normalized_digit(zcl_body.step_mode)
  local level = wheel_level(button_utils.numeric_value(zcl_body.step_size))
  local level_event
  local button_event

  if direction == 1 and level ~= nil then
    level_event = capabilities.switchLevel.level({ value = level })
    button_event = capabilities.button.button.up_hold()
  elseif direction == 3 and level ~= nil then
    level_event = capabilities.switchLevel.level({ value = 100 - level })
    button_event = capabilities.button.button.down_hold()
  end

  if level_event ~= nil then
    button_utils.emit_state_change(device, "hold_wheel", level_event)
    button_utils.emit_state_change(device, component_id, button_event)
  end
end

local knob_scene_toggle_handler = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  -- For the regular TS004F (not the knob version), both remote and scene signals are sent simultaneously, so defensive code needs to be implemented.
  -- Regular TS004F remotes send remote and scene signals together. Only knob
  -- fingerprints should treat this scene command as a button event.
  if not is_knob(device) then
    return
  end

  local component_id = button_utils.button_component_id_for_endpoint(device, ep)
  button_utils.emit_state_change(device, component_id, capabilities.button.button.pushed())
end

local knob_remote_wheel_handler = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  local component_id = button_utils.button_component_id_for_endpoint(device, ep)
  local zcl_body = get_zcl_body(zb_rx)
  if component_id == nil or zcl_body == nil then
    return
  end

  -- 00: Clockwise, 01: Count Clockwise
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)" -- it will return decimal value
  local direction = button_utils.byte_at(zcl_body.body_bytes)
  local event
  if direction == 0 then
    event = capabilities.button.button.up()
  elseif direction == 1 then
    event = capabilities.button.button.down()
  end

  button_utils.emit_state_change(device, component_id, event)
end

local button_handler = function(driver, device, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  local component_id = button_utils.button_component_id_for_endpoint(device, ep)
  local zcl_body = get_zcl_body(zb_rx)
  if component_id == nil or zcl_body == nil then
    return
  end

  -- 00: click, 01: double click, 02: held
  -- The same as "zb_rx.body.zcl_body.body_bytes:byte(1)" -- it will return decimal value
  local click_type = button_utils.byte_at(zcl_body.body_bytes)
  button_utils.emit_state_change(device, component_id, button_utils.standard_button_event(click_type))
end

local device_added = function(driver, device)
  log.info("<<---- Moon ---->> device_added")
  device:send(zcl_clusters.Groups.server.commands.RemoveAllGroups(device))

  -- knob manufacturer check
  local supported_values = is_knob(device) and KNOB_BUTTON_VALUES or STANDARD_BUTTON_VALUES
  button_utils.initialize_button_components(device, supported_values)
end

local configure_device = function(self, device)
  log.info("<<---- Moon ---->> configure_device")
  -- Tuya remotes can drain their batteries after binding and configuring
  -- reporting on the PowerConfiguration cluster. Keep the device's factory
  -- reporting configuration and only request the current value once.
  -- Do not enable this without excluding the default battery configuration.
  -- device:configure()
  if device:supports_server_cluster(PowerConfiguration.ID) then
    device:send(PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
  end
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
        [0x02] = knob_scene_toggle_handler,
        [0xFC] = knob_remote_wheel_handler,
        [0xFD] = button_handler
      },
      [zcl_clusters.Level.ID] = {
        -- ZCLCommandId
        [0x02] = knob_scene_wheel_handler
      },
      [zcl_clusters.ColorControl.ID] = {
        -- ZCLCommandId
        [0x4C] = knob_scene_hold_wheel_handler
      },
    },
  },
  lifecycle_handlers = {
    added = device_added,
    doConfigure = configure_device,
  },
  sub_drivers = {
    require("tuya-EF00")
  },
  -- Override the default battery configuration so a future call to
  -- device:configure() cannot bind or configure reporting for Tuya remotes.
  cluster_configurations = {
    [capabilities.battery.ID] = {
      {
        cluster = PowerConfiguration.ID,
        attribute = PowerConfiguration.attributes.BatteryPercentageRemaining.ID,
        minimum_interval = 30,
        maximum_interval = 21600,
        data_type = data_types.Uint8,
        reportable_change = 1,
        configurable = false,
        monitored = false,
      }
    }
  },
  -- Tuya buttons are sleepy battery devices. Do not poll monitored
  -- attributes when their reports are late or unsupported.
  health_check = false,
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
