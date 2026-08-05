local warnings = {}

package.preload["log"] = function()
  return {
    warn = function(message)
      table.insert(warnings, message)
    end,
  }
end

local function button_event(name, fields)
  local event = fields or {}
  event.name = name
  return event
end

package.preload["st.capabilities"] = function()
  return {
    button = {
      supportedButtonValues = function(values)
        return { name = "supportedButtonValues", value = values }
      end,
      button = {
        pushed = function(fields)
          return button_event("pushed", fields)
        end,
        double = function(fields)
          return button_event("double", fields)
        end,
        held = function(fields)
          return button_event("held", fields)
        end,
      },
    },
  }
end

local utils = dofile("drivers/zigbee-tuya-button/src/tuya_button_utils.lua")

local function new_component()
  return {
    events = {},
    emit_event = function(self, event)
      table.insert(self.events, event)
    end,
  }
end

local device = {
  fingerprinted_endpoint_id = 2,
  profile = {
    components = {
      main = new_component(),
      button1 = new_component(),
      button2 = new_component(),
      wheel = new_component(),
    },
  },
}

assert(utils.byte_at(2) == 2)
assert(utils.byte_at(string.char(0, 1, 2), 3) == 2)
assert(utils.byte_at({ value = string.char(7) }) == 7)
assert(utils.numeric_value({ value = 85 }) == 85)
assert(utils.normalized_digit({ value = "3" }) == 3)

assert(utils.standard_button_event(0).name == "pushed")
assert(utils.standard_button_event(1).name == "double")
assert(utils.standard_button_event(2).name == "held")
assert(utils.standard_button_event(3) == nil)

assert(utils.button_component_id_for_endpoint(device, 2) == "button1")
assert(utils.button_component_id_for_endpoint(device, 3) == "button2")
assert(utils.button_component_id_for_endpoint(device, 4) == nil)
assert(#warnings == 1)

utils.initialize_button_components(device, { "pushed", "double", "held" })
assert(#device.profile.components.main.events == 0)
assert(#device.profile.components.wheel.events == 0)
assert(#device.profile.components.button1.events == 2)
assert(#device.profile.components.button2.events == 2)
assert(device.profile.components.button1.events[2].state_change == false)

local event = utils.standard_button_event(0)
assert(utils.emit_state_change(device, "button1", event) == true)
assert(event.state_change == true)
assert(#device.profile.components.button1.events == 3)
assert(utils.emit_state_change(device, "missing", event) == false)

print("tuya_button_utils tests passed")
