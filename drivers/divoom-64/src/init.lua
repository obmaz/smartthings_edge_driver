local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local cosock = require "cosock"                 -- just for time
local socket = require "cosock.socket"          -- just for time
local json = require "dkjson"
local log = require "log"
local comms = require "comms"

local initialized = false
local base_url

-- Divoom API http://doc.divoom-gz.com/web/#/12?page_id=241
local function request(body)
  log.info("<<---- Moon ---->> request : ", body)
  -- Divoom 64 has only one endpoint and use POST
  status, response = comms.request('POST', base_url .. '/post', body)

  log.info("<<---- Moon ---->> request, status : ", status)
  log.info("<<---- Moon ---->> request, response : ", response)

  if status == true then
    responseTable, pos, err = json.decode(response, 1, nil)
    if responseTable.error_code == 0 then
      return true, responseTable;
    else
      return false;
    end
  else
    return false;
  end
end

-- android app에서는 호출이 안됨 2022-10-10
-- https://my.smartthings.com 웹에서는 호출됨
local function refresh_handler(driver, device, command)
  log.info("<<---- Moon ---->> refresh_handler")
  --local device_list = lanDriver:get_devices()
  --log.info("<<---- Moon ---->> refresh_data device_list:", device_list)
  local body = '{"Command": "Device/GetWeatherInfo"}'
  status, response = request(body);
  if status == true then
    local CurTemp = response.CurTemp;
    log.info("<<---- Moon ---->> refresh_data CurTemp:", CurTemp)
    device.profile.components['temperatureMeasurement']:emit_event(capabilities.temperatureMeasurement.temperature({ value = CurTemp, unit = 'C' }))
  end
end

local function device_init(driver, device)
  log.info("<<---- Moon ---->> device_init")
  initialized = true
  base_url = device.preferences.divoom64IP
end

local function device_added (driver, device)
  log.info("<<---- Moon ---->> device_added - key")
  device.profile.components['main']:emit_event(capabilities.switch.switch.on())
  device.profile.components['switch1']:emit_event(capabilities.switch.switch.on())
  local properties = '{"Command": "Device/GetDeviceTime"}'
  device.profile.components['temperatureMeasurement']:emit_event(capabilities.temperatureMeasurement.temperature({ value = 20, unit = 'C' }))
end

local function device_doconfigure (_, device)
  -- Nothing to do here!
end

local function device_removed(_, device)
  log.info("<<---- Moon ---->> device_removed : ", device.id .. ": " .. device.device_network_id)
  initialized = false
end

local function device_driver_switched(driver, device, event, args)
  log.info("<<---- Moon ---->> device_driver_switched")
end

local function shutdown_handler(driver, event)
  log.info("<<---- Moon ---->> shutdown_handler")
end

local function device_info_changed (driver, device, event, args)
  log.info("<<---- Moon ---->> device_info_changed")
  if args.old_st_store.preferences.divoom64IP ~= device.preferences.divoom64IP then
    base_url = device.preferences.divoom64IP;
  end
end

local function discovery_handler(driver, _, should_continue)
  if not initialized then
    log.info("Creating Web Request device")
    local MFG_NAME = 'SmartThings Community'
    local VEND_LABEL = 'Edge Divoom64'
    local MODEL = 'divoom64'
    local ID = 'divoom64' .. '_' .. socket.gettime()
    local PROFILE = 'LAN-Divoom64'

    local create_device_msg = {
      type = "LAN",
      device_network_id = ID,
      label = VEND_LABEL,
      profile = PROFILE,
      manufacturer = MFG_NAME,
      model = MODEL,
      vendor_provided_label = VEND_LABEL,
    }
    assert(driver:try_create_device(create_device_msg), "failed to create divoom64 device")
    log.debug("Exiting device creation")
  else
    log.info('divoom64 device already created')
  end
end

local switch_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> on_off_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> on_off_handler - command.command : ", command.command)
  local capa_on_off = (command.command == "off") and capabilities.switch.switch.off() or capabilities.switch.switch.on()

  if command.component == "main" then
  elseif command.component == "switch1" then
    local body = '{"Command": "Device/GetDeviceTime"}'
    status, responseTable = request(body);
    if status == true then
      device.profile.components[command.component]:emit_event(capa_on_off)
    end
  end
end

local lanDriver = Driver("lanDriver", {
  discovery = discovery_handler,
  lifecycle_handlers = {
    init = device_init,
    added = device_added,
    driverSwitched = device_driver_switched,
    infoChanged = device_info_changed,
    doConfigure = device_doconfigure,
    removed = device_removed
  },
  driver_lifecycle = shutdown_handler,
  supported_capabilities = {
    capabilities.refresh,
    capabilities.switch,
    capabilities.temperatureMeasurement
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = switch_handler,
      [capabilities.switch.commands.off.NAME] = switch_handler,
    },
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = switch_handler,
      [capabilities.switch.commands.off.NAME] = switch_handler,
    },
  }
})

log.info('LAN-Divoom64 Started')
lanDriver:run()