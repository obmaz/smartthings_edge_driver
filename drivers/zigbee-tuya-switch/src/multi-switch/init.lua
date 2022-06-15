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
local zcl_clusters = require "st.zigbee.zcl.clusters"

local remapSwitchTbl = {
  ["one"] = "switch1",
  ["two"] = "switch2",
  ["three"] = "switch3",
  ["one_two"] = "switchA",
  ["one_three"] = "switchB",
  ["two_three"] = "switchC",
  ["all"] = "all",
}
local function get_ep_offset(device)
  return device.fingerprinted_endpoint_id - 1
end

local function get_remap_switch(device)
  log.info("<<---- Moon ---->> multi / remapSwitch")
  local remapSwitch = remapSwitchTbl[device.preferences.remapSwitch]

  if remapSwitch == nil then
    return "switch1"
  else
    return remapSwitch
  end
end

local function send_multi_switch(device, s1, s2, s3, ev, on_off)
  device.profile.components["main"]:emit_event(ev)

  if s1 == true then
    device.profile.components["switch1"]:emit_event(ev)
    device:send_to_component("switch1", on_off)
  end

  if s2 == true then
    device.profile.components["switch2"]:emit_event(ev)
    device:send_to_component("switch2", on_off)
  end

  if s3 == true then
    device.profile.components["switch3"]:emit_event(ev)
    device:send_to_component("switch3", on_off)
  end
end

local on_off_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> multi / on_off_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> multi / on_off_handler - command.command : ", command.command)
  local capa_on_off = (command.command == "off") and capabilities.switch.switch.off() or capabilities.switch.switch.on()
  local cluster_on_off = (command.command == "off") and zcl_clusters.OnOff.server.commands.Off(device) or zcl_clusters.OnOff.server.commands.On(device)

  -- Due to legacy profile and automation, remapSwitchTbl structure cannot be changed
  if command.component == "main" and get_remap_switch(device) == "all" then
    send_multi_switch(device, true, true, true, capa_on_off, cluster_on_off)
  elseif command.component == "main" and get_remap_switch(device) == "switchA" then
    send_multi_switch(device, true, true, false, capa_on_off, cluster_on_off)
  elseif command.component == "main" and get_remap_switch(device) == "switchB" then
    send_multi_switch(device, true, false, true, capa_on_off, cluster_on_off)
  elseif command.component == "main" and get_remap_switch(device) == "switchC" then
    send_multi_switch(device, false, true, true, capa_on_off, cluster_on_off)
  else
    if command.component == "main" or command.component == get_remap_switch(device) then
      device.profile.components["main"]:emit_event(capa_on_off)
      command.component = get_remap_switch(device)
    end

    -- Note : The logic is the same, but it uses endpoint.
    -- From hub 41.x end_point should be int (Note : Lua don't have int primitive type
    --local endpoint = device:get_endpoint_for_component_id(command.component)
    --endpoint = math.floor(endpoint)
    --device:emit_event_for_endpoint(endpoint, capa_on_off)
    --device:send(cluster_on_off:to_endpoint(endpoint))

    device.profile.components[command.component]:emit_event(capa_on_off)
    device:send_to_component(command.component, cluster_on_off)
  end
end

-- when receive zb_rx from device
local attr_handler = function(driver, device, OnOff, zb_rx)
  local ep = zb_rx.address_header.src_endpoint.value
  log.info("<<---- Moon ---->> multi / attr_handler ep :", ep)

  local number = ep - get_ep_offset(device)
  local component_id = string.format("switch%d", number)
  log.info("<<---- Moon ---->> multi / attr_handler :", component_id)

  local clickType = OnOff.value
  local ev = capabilities.switch.switch.off()
  if clickType == true then
    ev = capabilities.switch.switch.on()
  end

  if component_id == get_remap_switch(device) then
    device.profile.components["main"]:emit_event(ev)
  end
  device.profile.components[component_id]:emit_event(ev)
  --device:emit_event_for_endpoint(src_endpoint, ev) -- it cannot be used since endpoint_to_component does not handle main button sync
  syncMainComponent(device)
end

local component_to_endpoint = function(device, component_id)
  log.info("<<---- Moon ---->> multi / component_to_endpoint - component_id : ", component_id)
  local ep = component_id:match("switch(%d)")
  -- From hub 41.x end_point should be int (Note : Lua don't have int primitive type)
  -- Use math.floor or tonumber to remove decimal point
  return math.floor(ep + get_ep_offset(device))
end

-- It will not be called due to received_handler in zigbee_handlers
local endpoint_to_component = function(device, ep)
  log.info("<<---- Moon ---->> multi / endpoint_to_component - endpoint : ", ep)
  local number = ep - get_ep_offset(device)
  return string.format("switch%d", number)
end

function syncMainComponent(device)
  local component_id = get_remap_switch(device)
  log.info("<<---- Moon ---->> multi / syncMainComponent : ", component_id)
  local remapButtonStatus = device:get_latest_state(component_id, "switch", "switch", "off", nil)
  local switch1Status = device:get_latest_state("switch1", "switch", "switch", "off", nil)
  local switch2Status = device:get_latest_state("switch2", "switch", "switch", "off", nil)
  local switch3Status = device:get_latest_state("switch3", "switch", "switch", "off", nil)
  local ev = capabilities.switch.switch.on()

  if component_id == "all" then
    if switch1Status == "off" or switch2Status == "off" or switch3Status == "off" then
      ev = capabilities.switch.switch.off()
    end
  elseif component_id == "switchA" then
    if switch1Status == "off" or switch2Status == "off" then
      ev = capabilities.switch.switch.off()
    end
  elseif component_id == "switchB" then
    if switch1Status == "off" or switch3Status == "off" then
      ev = capabilities.switch.switch.off()
    end
  elseif component_id == "switchC" then
    if switch2Status == "off" or switch3Status == "off" then
      ev = capabilities.switch.switch.off()
    end
  elseif remapButtonStatus == "off" then
    ev = capabilities.switch.switch.off()
  end

  device.profile.components["main"]:emit_event(ev)
end

local device_init = function(self, device)
  log.info("<<---- Moon ---->> multi / device_init")
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component) -- emit_event_for_endpoint
end

local device_added = function(driver, device)
  log.info("<<---- Moon ---->> multi / device_added")
  -- Workaround : Should emit or send to enable capabilities UI
  for key, value in pairs(device.profile.components) do
    log.info("<<---- Moon ---->> multi / device_added - key : ", key)
    device.profile.components[key]:emit_event(capabilities.switch.switch.on())
    device:send_to_component(key, zcl_clusters.OnOff.server.commands.On(device))
  end
  device:refresh()
end

local device_driver_switched = function(driver, device, event, args)
  log.info("<<---- Moon ---->> multi / device_driver_switched")
  syncMainComponent(device)
end

local device_info_changed = function(driver, device, event, args)
  log.info("<<---- Moon ---->> multi / device_info_changed")
  syncMainComponent(device)
end

local configure_device = function(self, device)
  log.info("<<---- Moon ---->> multi / configure_device")
  device:configure()
end

local ZIGBEE_TUYA_SWITCH_MULTI_FINGERPRINTS = {
  { mfr = "_TZ3000_7hp93xpr", model = "TS0002" },
  { mfr = "_TZ3000_vjhyd6ar", model = "TS0002" },
  { mfr = "_TZ3000_c0wbnbbf", model = "TS0003" },
  { mfr = "_TZ3000_wqfdvxen", model = "TS0003" },
  { mfr = "_TZ3000_tbfw3xj0", model = "TS0003" },
  { mfr = "3A Smart Home DE", model = "LXN-2S27LX1.0" },
  { mfr = "3A Smart Home DE", model = "LXN-3S27LX1.0" },
  { mfr = "DAWON_DNS", model = "PM-S350-ZB" },
  { mfr = "DAWON_DNS", model = "PM-S250-ZB" },
  { mfr = "DAWON_DNS", model = "PM-S340-ZB" },
  { mfr = "DAWON_DNS", model = "PM-S240-ZB" },
  { mfr = "_TZ3000_jl7qyupf", model = "TS0012" },
  { mfr = "_TZ3000_k008kbls", model = "TS0012" },
  { mfr = "_TZ3000_wu0shw0i", model = "TS0013" },
  { mfr = "FeiBit", model = "FNB56-ZSW03LX2.0" },
  { mfr = "_TYZB01_mqel1whf", model = "TS0013" },
  { mfr = "_TYZB01_8gqspaab", model = "TS0003" },
  { mfr = "FeiBit", model = "FNB56-ZSW02LX2.0" },
  { mfr = "_TZ3000_ecgiiid3", model = "TS0003" },
  { mfr = "_TZ3000_odzoiovu", model = "TS0003" },
  { mfr = "3A Smart Home DE", model = "LXN59-2S7LX1.0" },
  { mfr = "_TZ3000_qewo8dlz", model = "TS0013" },
  { mfr = "_TZ3000_fvh3pjaz", model = "TS0012" },
  { mfr = "_TZ3000_wyhuocal", model = "TS0013" },
}

local is_multi_switch = function(opts, driver, device)
  for _, fingerprint in ipairs(ZIGBEE_TUYA_SWITCH_MULTI_FINGERPRINTS) do
    log.info("<<---- Moon ---->> multi / is_multi_switch :", device:pretty_print())

    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      log.info("<<---- Moon ---->> multi / is_multi_switch : true / device.fingerprinted_endpoint_id :", device.fingerprinted_endpoint_id)
      return true
    end
  end

  log.info("<<---- Moon ---->> multi / is_multi_switch : false")
  return false
end

local multi_switch = {
  NAME = "mutil switch",
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_off_handler,
      [capabilities.switch.commands.off.NAME] = on_off_handler,
    },
  },
  zigbee_handlers = {
    attr = {
      [zcl_clusters.OnOff.ID] = {
        [zcl_clusters.OnOff.attributes.OnOff.ID] = attr_handler
      }
    }
  },
  lifecycle_handlers = {
    init = device_init,
    added = device_added,
    driverSwitched = device_driver_switched,
    infoChanged = device_info_changed,
    doConfigure = configure_device
  },
  can_handle = is_multi_switch,
}

return multi_switch
