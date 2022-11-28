local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local cosock = require "cosock"                 -- just for time
local socket = require "cosock.socket"          -- just for time
local json = require "dkjson"
local log = require "log"
local comms = require "comms"

local initialized = false
local base_url
local divoomChannel = capabilities['imageafter45121.divoomChannel']

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

local function get_channel(device)
  status, response = request('{"Command": "Channel/GetIndex"}');
  if status == true then
    local SelectIndex = response.SelectIndex;
    log.info("<<---- Moon ---->> Channel/GetIndex: ", SelectIndex)
    if SelectIndex == 0 then
      selectIndexValue = "Faces"
    elseif SelectIndex == 1 then
      selectIndexValue = "Cloud Channel"
    elseif SelectIndex == 2 then
      selectIndexValue = "Visualizer"
    elseif SelectIndex == 3 then
      selectIndexValue = "Custom"
    elseif SelectIndex == 4 then
      selectIndexValue = "Black Screen"
    end
    device.profile.components['channel']:emit_event(divoomChannel.channel({ value = selectIndexValue }))
  end
end

local function get_all_conf(device)
  status, response = request('{"Command": "Channel/GetAllConf"}');
  if status == true then
    local Brightness = response.Brightness;
    log.info("<<---- Moon ---->> Channel/GetAllConf Brightness : ", Brightness)
    device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = Brightness }))

    local RotationFlag = response.RotationFlag;
    log.info("<<---- Moon ---->> Channel/GetAllConf RotationFlag : ", RotationFlag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = RotationFlag }))

    local ClockTime = response.ClockTime;
    log.info("<<---- Moon ---->> Channel/GetAllConf ClockTime : ", ClockTime)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = ClockTime }))

    local GalleryTime = response.GalleryTime;
    log.info("<<---- Moon ---->> Channel/GetAllConf GalleryTime : ", GalleryTime)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = GalleryTime }))

    local SingleGalleyTime = response.SingleGalleyTime;
    log.info("<<---- Moon ---->> Channel/GetAllConf SingleGalleyTime : ", SingleGalleyTime)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = SingleGalleyTime }))

    local PowerOnChannelId = response.PowerOnChannelId;
    log.info("<<---- Moon ---->> Channel/GetAllConf PowerOnChannelId : ", PowerOnChannelId)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = PowerOnChannelId }))

    local GalleryShowTimeFlag = response.GalleryShowTimeFlag;
    log.info("<<---- Moon ---->> Channel/GetAllConf GalleryShowTimeFlag : ", GalleryShowTimeFlag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = GalleryShowTimeFlag }))

    local CurClockId = response.CurClockId;
    log.info("<<---- Moon ---->> Channel/GetAllConf CurClockId : ", CurClockId)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = CurClockId }))

    local Time24Flag = response.Time24Flag;
    log.info("<<---- Moon ---->> Channel/GetAllConf Time24Flag : ", Time24Flag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = Time24Flag }))

    local TemperatureMode = response.TemperatureMode;
    log.info("<<---- Moon ---->> Channel/GetAllConf TemperatureMode : ", TemperatureMode)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = TemperatureMode }))

    local GyrateAngle = response.GyrateAngle;
    log.info("<<---- Moon ---->> Channel/GetAllConf GyrateAngle : ", GyrateAngle)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = GyrateAngle }))

    local MirrorFlag = response.MirrorFlag;
    log.info("<<---- Moon ---->> Channel/GetAllConf MirrorFlag : ", MirrorFlag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = MirrorFlag }))

    local LightSwitch = response.LightSwitch;
    log.info("<<---- Moon ---->> Channel/GetAllConf LightSwitch : ", LightSwitch)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = LightSwitch }))
  end
end

local function get_weather_info(device)
  status, response = request('{"Command": "Device/GetWeatherInfo"}');
  if status == true then
    local CurTemp = response.CurTemp;
    log.info("<<---- Moon ---->> Device/GetWeatherInfo: ", CurTemp)
    device.profile.components['system']:emit_event(capabilities.temperatureMeasurement.temperature({ value = CurTemp, unit = 'C' }))
  end
end

local function refresh_handler(driver, device, command)
  log.info("<<---- Moon ---->> refresh_handler")
  get_channel(device)
  get_all_conf(device)
  get_weather_info(device)
end

local function device_init(driver, device)
  log.info("<<---- Moon ---->> device_init")
  initialized = true
  base_url = device.preferences.divoomIP
end

local function device_added (driver, device)
  log.info("<<---- Moon ---->> device_added - key")
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
  if args.old_st_store.preferences.divoomIP ~= device.preferences.divoomIP then
    base_url = device.preferences.divoomIP;
  end
end

local function discovery_handler(driver, _, should_continue)
  if not initialized then
    log.info("Creating Web Request device")
    local MFG_NAME = 'SmartThings Community'
    local VEND_LABEL = 'Edge Divoom'
    local MODEL = 'divoom'
    local ID = 'divoom' .. '_' .. socket.gettime()
    local PROFILE = 'LAN-Divoom'

    local create_device_msg = {
      type = "LAN",
      device_network_id = ID,
      label = VEND_LABEL,
      profile = PROFILE,
      manufacturer = MFG_NAME,
      model = MODEL,
      vendor_provided_label = VEND_LABEL,
    }
    assert(driver:try_create_device(create_device_msg), "failed to create divoom device")
    log.debug("Exiting device creation")
  else
    log.info('divoom device already created')
  end
end

local bright_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> bright_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> bright_handler - command.args.level : ", command.args.level)
  status, response = request(string.format('{"Command": "Channel/SetBrightness", "Brightness": %s}', command.args.level));
  refresh_handler(driver, device, command)
end

local channel_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> channel_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> channel_handler - command.command : ", command.args.value)
  status, response = request(string.format('{"Command": "Channel/SetIndex", "SelectIndex": %d}', command.args.value));
  refresh_handler(driver, device, command)
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
    [capabilities.switchLevel.ID] = {
      [capabilities.switchLevel.commands.setLevel.NAME] = bright_handler,
    },
    [divoomChannel.ID] = {
      [divoomChannel.commands.setChannel.NAME] = channel_handler,
    },
  }
})

log.info('LAN-Divoom Started')
lanDriver:run()