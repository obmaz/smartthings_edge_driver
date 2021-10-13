-- Zigbee Tuya Switch
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

local remapSwitchTbl = {
  ["one"] = "switch1",
  ["two"] = "switch2",
  ["three"] = "switch3",
  ["all"] = "all",
}

local function getRemapSwitch(device)
  log.info("--------- Moon --------->> remapSwitch")
  local remapSwitch = remapSwitchTbl[device.preferences.remapSwitch]

  if remapSwitch == nil then
    return "main"
  else
    return remapSwitch
  end
end

local on_handler = function(driver, device, command)
  log.info("--------- Moon --------->> on_handler - component : ", command.component)

  if "all" == getRemapSwitch(device) then
    for key, value in pairs(device.profile.components) do
      log.info("--------- Moon --------->> on_handler - key : ", key)
      device.profile.components[key]:emit_event(capabilities.switch.switch.on())
      if key ~= "main" then
        device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
      end
    end
    return
  end

  if command.component == getRemapSwitch(device) or command.component == "main" then
    device.profile.components["main"]:emit_event(capabilities.switch.switch.on())
    command.component = getRemapSwitch(device)
  end

  device.profile.components[command.component]:emit_event(capabilities.switch.switch.on())
  device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.On(device))
end

local off_handler = function(driver, device, command)
  log.info("--------- Moon --------->> off_handler - component : ", command.component)

  if "all" == getRemapSwitch(device) then
    for key, value in pairs(device.profile.components) do
      log.info("--------- Moon --------->> off_handler - key : ", key)
      device.profile.components[key]:emit_event(capabilities.switch.switch.off())
      if key ~= "main" then
        device:send_to_component(key, zcl_clusters.OnOff.server.commands.Off(device))
      end
    end
    return
  end

  if command.component == getRemapSwitch(device) or command.component == "main" then
    device.profile.components["main"]:emit_event(capabilities.switch.switch.off())
    command.component = getRemapSwitch(device)
  end

  -- Note : The logic is the same, but it uses endpoint.
  --local endpoint = device:get_endpoint_for_component_id(command.component)
  --device:emit_event_for_endpoint(endpoint, capabilities.switch.switch.off())
  --device:send(zcl_clusters.OnOff.server.commands.Off(device):to_endpoint(endpoint))
  device.profile.components[command.component]:emit_event(capabilities.switch.switch.off())
  device:send_to_component(command.component, zcl_clusters.OnOff.server.commands.Off(device))
end

local received_handler = function(driver, device, OnOff, zb_rx)

  local ep = zb_rx.address_header.src_endpoint.value
  local component_id = string.format("switch%d", ep)
  log.info("--------- Moon --------->> received_handler : ", component_id)

  local clickType = OnOff.value
  local ev = capabilities.switch.switch.off()
  if clickType == true then
    ev = capabilities.switch.switch.on()
  end

  ev.state_change = true
  if component_id == getRemapSwitch(device) then
    device.profile.components["main"]:emit_event(ev)
  end
  --todo: 1gang switch 1은 main 임
  device.profile.components[component_id]:emit_event(ev)

  syncComponent(device)
end

local component_to_endpoint = function(device, component_id)
  log.info("--------- Moon --------->> component_to_endpoint - component_id : ", component_id)
  local ep = component_id:match("switch(%d)")
  return ep and tonumber(ep) or device.fingerprinted_endpoint_id
end

-- It will not be called due to received_handler in zigbee_handlers
local endpoint_to_component = function(device, ep)
  log.info("--------- Moon --------->> endpoint_to_component - endpoint : ", ep)
  local component_id = string.format("switch%d", ep)
  return component_id
end

function syncComponent(device)
  local component_id = getRemapSwitch(device)
  local remapButtonStatus = device:get_latest_state(component_id, "switch", "switch", "off", nil)
  local ev = capabilities.switch.switch.on()

  if component_id == "all" then
    for key, value in pairs(device.profile.components) do
      local componentStatus = device:get_latest_state(key, "switch", "switch", "off", nil)
      if key ~= "main" and componentStatus == "off" then
        ev = capabilities.switch.switch.off()
        break
      end
    end
  else
    --if status ~= nil then
    if component_id ~= "all" and remapButtonStatus == "off" then
      ev = capabilities.switch.switch.off()
    end
    --end
  end
  device.profile.components["main"]:emit_event(ev)
end

local device_info_changed = function(driver, device, event, args)
  syncComponent(device)
end

local device_init = function(self, device)
  log.info("--------- Moon --------->> device_init")
  device:set_component_to_endpoint_fn(component_to_endpoint) -- get_endpoint_for_component_id
  device:set_endpoint_to_component_fn(endpoint_to_component)
end

local device_added = function(driver, device)
  log.info("--------- Moon --------->> device_added")
  -- Workaround : Should emit or send to enable capabilities UI
  for key, value in pairs(device.profile.components) do
    log.info("--------- Moon --------->> device_added - key : ", key)
    device.profile.components[key]:emit_event(capabilities.switch.switch.on())
    device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
  end
end

local function configure_device(self, device)
  device:configure()
end

local ZIGBEE_TUYA_SWITCH_FINGERPRINTS = {
  { mfr = "_TZ3000_7hp93xpr", model = "TS0002" },
  { mfr = "_TZ3000_c0wbnbbf", model = "TS0003" }
}

local is_multi_gang = function(opts, driver, device)
  for _, fingerprint in ipairs(ZIGBEE_TUYA_SWITCH_FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      log.info("--------- Moon --------->> is_multi_gang : true")
      return true
    end
  end

  log.info("--------- Moon --------->> is_multi_gang : false")
  return false
end

local zigbee_tuya_switch_driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.refresh
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_handler,
      [capabilities.switch.commands.off.NAME] = off_handler
    }
  },
  zigbee_handlers = {
    attr = {
      [zcl_clusters.OnOff.ID] = {
        [zcl_clusters.OnOff.attributes.OnOff.ID] = received_handler
      }
    }
  },
  lifecycle_handlers = {
    infoChanged = device_info_changed,
    init = device_init,
    added = device_added,
    doConfigure = configure_device
  },
  can_handle = is_multi_gang
}

defaults.register_for_default_handlers(zigbee_tuya_switch_driver_template, zigbee_tuya_switch_driver_template.supported_capabilities)
local zigbee_driver = ZigbeeDriver("zigbee-tuya-switch", zigbee_tuya_switch_driver_template)
zigbee_driver:run()