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

local utils = {}

local BUTTON_COMPONENT_PATTERN = "^button%d+$"

function utils.standard_button_event(click_type)
  if click_type == 0 then
    return capabilities.button.button.pushed()
  elseif click_type == 1 then
    return capabilities.button.button.double()
  elseif click_type == 2 then
    return capabilities.button.button.held()
  end

  return nil
end

function utils.byte_at(value, index)
  if value == nil then
    return nil
  end

  index = index or 1

  if type(value) == "number" then
    return value
  elseif type(value) == "string" then
    return string.byte(value, index)
  end

  local ok, result = pcall(function()
    return value:byte(index)
  end)
  if ok and result ~= nil then
    return result
  end

  ok, result = pcall(function()
    return value.value
  end)
  if ok and result ~= nil and result ~= value then
    return utils.byte_at(result, index)
  end

  return nil
end

function utils.numeric_value(value)
  if value == nil then
    return nil
  elseif type(value) == "number" then
    return value
  elseif type(value) == "string" then
    return tonumber(value) or string.byte(value, 1)
  end

  local ok, result = pcall(function()
    return value.value
  end)
  if ok and result ~= nil and result ~= value then
    return utils.numeric_value(result)
  end

  return nil
end

function utils.normalized_digit(value)
  local byte = utils.byte_at(value)
  if byte ~= nil and byte >= string.byte("0") and byte <= string.byte("9") then
    return byte - string.byte("0")
  end
  return byte
end

function utils.button_component_id(device, button_number)
  if type(button_number) ~= "number" or button_number < 1 or button_number % 1 ~= 0 then
    log.warn(string.format("Ignoring invalid button number: %s", tostring(button_number)))
    return nil
  end

  local component_id = string.format("button%d", button_number)
  if device.profile.components[component_id] == nil then
    log.warn(string.format("Ignoring event for missing component: %s", component_id))
    return nil
  end

  return component_id
end

function utils.button_component_id_for_endpoint(device, endpoint)
  if type(endpoint) ~= "number" then
    log.warn(string.format("Ignoring invalid endpoint: %s", tostring(endpoint)))
    return nil
  end

  local fingerprinted_endpoint = device.fingerprinted_endpoint_id or 1
  return utils.button_component_id(device, endpoint - fingerprinted_endpoint + 1)
end

function utils.emit_state_change(device, component_id, event)
  local component = component_id and device.profile.components[component_id] or nil
  if component == nil or event == nil then
    return false
  end

  event.state_change = true
  component:emit_event(event)
  return true
end

function utils.initialize_button_components(device, supported_values)
  for component_id, component in pairs(device.profile.components) do
    if component_id:match(BUTTON_COMPONENT_PATTERN) then
      component:emit_event(capabilities.button.supportedButtonValues(supported_values))
      component:emit_event(capabilities.button.button.pushed({ state_change = false }))
    end
  end
end

return utils
