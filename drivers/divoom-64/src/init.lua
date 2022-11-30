local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local cosock = require "cosock"                 -- just for time
local socket = require "cosock.socket"          -- just for time
local json = require "dkjson"
local log = require "log"
local comms = require "comms"
local initialized = false
local base_url
local capavility_channel = capabilities['imageafter45121.channel']
local capavility_weather = capabilities['imageafter45121.weather']
local capavility_message = capabilities['imageafter45121.message']

-- Divoom API http://doc.divoom-gz.com/web/#/12?page_id=241
local function request(body)
  log.info("<<---- Moon ---->> request : ", body)
  -- Divoom 64 has only one endpoint and use POST
  local status, response = comms.request('POST', base_url .. '/post', body)

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
  local payload = string.format('{"Command": "Channel/GetIndex"}')
  local status, response = request(payload);

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
    device.profile.components['main']:emit_event(capavility_channel.channel({ value = selectIndexValue }))
  end
end

local function get_all_conf(device)
  --  { "RotationFlag": 1, "ClockTime": 30, "GalleryTime": 50, "SingleGalleyTime": 3, "PowerOnChannelId": 5, "GalleryShowTimeFlag": 0, "CurClockId": 182, "Time24Flag": 1, "TemperatureMode": 0, "GyrateAngle": 0, "MirrorFlag": 0, "LightSwitch": 1 }
  local payload = string.format('{"Command": "Channel/GetAllConf"}')
  local status, response = request(payload);
  if status == true then
    local LightSwitch = response.LightSwitch;
    log.info("<<---- Moon ---->> Channel/GetAllConf LightSwitch : ", LightSwitch)
    local on_off = (LightSwitch == 0) and capabilities.switch.switch.off() or capabilities.switch.switch.on()
    device.profile.components['main']:emit_event(on_off)

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

    TemperatureMode = response.TemperatureMode;
    log.info("<<---- Moon ---->> Channel/GetAllConf TemperatureMode : ", TemperatureMode)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = TemperatureMode }))

    local GyrateAngle = response.GyrateAngle;
    log.info("<<---- Moon ---->> Channel/GetAllConf GyrateAngle : ", GyrateAngle)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = GyrateAngle }))

    local MirrorFlag = response.MirrorFlag;
    log.info("<<---- Moon ---->> Channel/GetAllConf MirrorFlag : ", MirrorFlag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = MirrorFlag }))
  end
end

local function get_weather_info(device)
  local payload = string.format('{"Command": "Device/GetWeatherInfo"}')
  local status, response = request(payload);
  --{ "error_code": 0, "Weather":"Sunny", "CurTemp":8.080000, "MinTemp":7.140000, "MaxTemp":11.050000, "Pressure":1015, "Humidity":84, "Visibility":10000, "WindSpeed":5.140000 }
  if status == true then
    local CurTemp = response.CurTemp;
    local Weather = response.Weather;
    local CelsiusOrFahrenheit = (TemperatureMode == 0) and 'C' or 'F'
    log.info("<<---- Moon ---->> Device/GetWeatherInfo: ", CurTemp)
    device.profile.components['system']:emit_event(capabilities.temperatureMeasurement.temperature({ value = CurTemp, unit = CelsiusOrFahrenheit }))
    device.profile.components['system']:emit_event(capavility_weather.weather({ value = Weather }))
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
  refresh_handler(driver, device, null)
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

local switch_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> on_off_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> on_off_handler - command.command : ", command.command)
  local on_off = (command.command == "off") and 0 or 1
  local payload = string.format('{"Command": "Channel/OnOffScreen", "OnOff": %d}', on_off)
  local status, response = request(payload);

  refresh_handler(driver, device, command)
end

local bright_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> bright_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> bright_handler - command.args.level : ", command.args.level)
  local payload = string.format('{"Command": "Channel/SetBrightness", "Brightness": %s}', command.args.level)
  local status, response = request(payload);

  refresh_handler(driver, device, command)
end

local channel_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> channel_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> channel_handler - command.args.value : ", command.args.value)
  local payload = string.format('{"Command": "Channel/SetIndex", "SelectIndex": %d}', command.args.value)
  local status, response = request(payload);

  refresh_handler(driver, device, command)
end

local message_handler = function(driver, device, command)
  log.info("<<---- Moon ---->> message_handler - command.component : ", command.component)
  log.info("<<---- Moon ---->> message_handler - command.args.value : ", command.args.value)

  local payload1 = string.format('{"Command":"Draw/ResetHttpGifId"}')
  local status1, response1 = request(payload1)

  local payload2 = string.format('{"Command":"Draw/SendHttpGif","PicNum":1,"PicWidth":64,"PicOffset":0,"PicID":1,"PicSpeed":10,"PicData":""}')
  local status2, response2 = request(payload2)

  local item1 = string.format(
      '{"TextId":1, "type":22,"x":0, "y":0, "dir":0, "font":2, "TextWidth":64, "Textheight":16, "speed":50, "TextString": "Sending Time: %s", "color":"#DDDDDD", "align":2}', os.date())
  local item2 = string.format(
      '{"TextId":2, "type":22,"x":0, "y":16, "dir":0, "font":2, "TextWidth":64, "Textheight":16, "speed":50, "TextString": "%s", "color":"#FFFFFF", "align":2}', command.args.value)
  local payload3 = string.format('{"Command":"Draw/SendHttpItemList", "ItemList":[%s,%s]}', item1, item2)

  local status3, response3 = request(payload3)
  -- Note: Draw/CommandList로 같이 보내면 작동이 잘 안됨

  log.info("<<---- Moon ---->> message_handler - status : ", status3)
  if status1 == true and status2 == true and status3 == true then
    device.profile.components['system']:emit_event(capavility_message.message({ value = "Sending Success" }))
  else
    device.profile.components['system']:emit_event(capavility_message.message({ value = "Sending Fail" }))
  end

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
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = switch_handler,
      [capabilities.switch.commands.off.NAME] = switch_handler,
    },
    [capabilities.switchLevel.ID] = {
      [capabilities.switchLevel.commands.setLevel.NAME] = bright_handler,
    },
    [capavility_channel.ID] = {
      [capavility_channel.commands.setChannel.NAME] = channel_handler,
    },
    [capavility_message.ID] = {
      [capavility_message.commands.setMessage.NAME] = message_handler,
    },
  }
})

log.info('LAN-Divoom Started')
lanDriver:run()