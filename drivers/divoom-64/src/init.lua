local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local cosock = require "cosock"                 -- just for time
local socket = require "cosock.socket"          -- just for time
local json = require "dkjson"
local log = require "log"
local comms = require "comms"
local initialized = false
local base_url
local capability_channel = capabilities['imageafter45121.channel']
local capability_cloud_channel = capabilities['imageafter45121.cloudChannel']
local capability_visualizer_channel = capabilities['imageafter45121.visualizerChannel']
local capability_custom_channel = capabilities['imageafter45121.customChannel']
local capability_weather = capabilities['imageafter45121.weather']
local capability_message = capabilities['imageafter45121.message']

-- Divoom API http://doc.divoom-gz.com/web/#/12?page_id=241
local function request(body)
  log.info("<<---- Divoom ---->> request : ", body)
  -- Divoom 64 has only one endpoint and use POST
  local status, response = comms.request('POST', base_url .. '/post', body)

  log.info("<<---- Divoom ---->> request, status : ", status)
  log.info("<<---- Divoom ---->> request, response : ", response)

  if status then
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

  if status then
    local SelectIndex = response.SelectIndex;
    log.info("<<---- Divoom ---->> Channel/GetIndex: ", SelectIndex)
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

    log.info("<<---- Divoom ---->> selectIndexValue Channel/GetIndex: ", selectIndexValue)

    device.profile.components['main']:emit_event(capability_channel.channel({ value = selectIndexValue }))
  end
end

local function get_all_conf(device)
  --  { "RotationFlag": 1, "ClockTime": 30, "GalleryTime": 50, "SingleGalleyTime": 3, "PowerOnChannelId": 5, "GalleryShowTimeFlag": 0, "CurClockId": 182, "Time24Flag": 1, "TemperatureMode": 0, "GyrateAngle": 0, "MirrorFlag": 0, "LightSwitch": 1 }
  local payload = string.format('{"Command": "Channel/GetAllConf"}')
  local status, response = request(payload);
  if status then
    local LightSwitch = response.LightSwitch;
    log.info("<<---- Divoom ---->> Channel/GetAllConf LightSwitch : ", LightSwitch)
    local on_off = (LightSwitch == 0) and capabilities.switch.switch.off() or capabilities.switch.switch.on()
    device.profile.components['main']:emit_event(on_off)

    local Brightness = response.Brightness;
    log.info("<<---- Divoom ---->> Channel/GetAllConf Brightness : ", Brightness)
    device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = Brightness }))

    local RotationFlag = response.RotationFlag;
    log.info("<<---- Divoom ---->> Channel/GetAllConf RotationFlag : ", RotationFlag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = RotationFlag }))

    local ClockTime = response.ClockTime;
    log.info("<<---- Divoom ---->> Channel/GetAllConf ClockTime : ", ClockTime)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = ClockTime }))

    local GalleryTime = response.GalleryTime;
    log.info("<<---- Divoom ---->> Channel/GetAllConf GalleryTime : ", GalleryTime)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = GalleryTime }))

    local SingleGalleyTime = response.SingleGalleyTime;
    log.info("<<---- Divoom ---->> Channel/GetAllConf SingleGalleyTime : ", SingleGalleyTime)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = SingleGalleyTime }))

    local PowerOnChannelId = response.PowerOnChannelId;
    log.info("<<---- Divoom ---->> Channel/GetAllConf PowerOnChannelId : ", PowerOnChannelId)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = PowerOnChannelId }))

    local GalleryShowTimeFlag = response.GalleryShowTimeFlag;
    log.info("<<---- Divoom ---->> Channel/GetAllConf GalleryShowTimeFlag : ", GalleryShowTimeFlag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = GalleryShowTimeFlag }))

    local CurClockId = response.CurClockId;
    log.info("<<---- Divoom ---->> Channel/GetAllConf CurClockId : ", CurClockId)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = CurClockId }))

    local Time24Flag = response.Time24Flag;
    log.info("<<---- Divoom ---->> Channel/GetAllConf Time24Flag : ", Time24Flag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = Time24Flag }))

    TemperatureMode = response.TemperatureMode;
    log.info("<<---- Divoom ---->> Channel/GetAllConf TemperatureMode : ", TemperatureMode)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = TemperatureMode }))

    local GyrateAngle = response.GyrateAngle;
    log.info("<<---- Divoom ---->> Channel/GetAllConf GyrateAngle : ", GyrateAngle)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = GyrateAngle }))

    local MirrorFlag = response.MirrorFlag;
    log.info("<<---- Divoom ---->> Channel/GetAllConf MirrorFlag : ", MirrorFlag)
    --device.profile.components['system']:emit_event(capabilities.switchLevel.level({ value = MirrorFlag }))
  end
end

local function get_weather_info(device)
  local payload = string.format('{"Command": "Device/GetWeatherInfo"}')
  local status, response = request(payload);
  --{ "error_code": 0, "Weather":"Sunny", "CurTemp":8.080000, "MinTemp":7.140000, "MaxTemp":11.050000, "Pressure":1015, "Humidity":84, "Visibility":10000, "WindSpeed":5.140000 }
  if status then
    local CurTemp = response.CurTemp;
    local Weather = response.Weather;
    local CelsiusOrFahrenheit = (TemperatureMode == 0) and 'C' or 'F'
    log.info("<<---- Divoom ---->> Device/GetWeatherInfo: ", CurTemp)
    device.profile.components['system']:emit_event(capabilities.temperatureMeasurement.temperature({ value = CurTemp, unit = CelsiusOrFahrenheit }))
    device.profile.components['system']:emit_event(capability_weather.weather({ value = Weather }))
  end
end

local function refresh_handler(driver, device, command)
  log.info("<<---- Divoom ---->> refresh_handler")
  get_channel(device)
  -- Divoom API에 특정 Channel의 Index를 가지고 오는 방법이 없음, emit 시 상태를 설정함
  --get_cloud_channel(device)
  --get_visualizer_channel(device)
  --get_custom_channel(device)
  get_all_conf(device)
  get_weather_info(device)
end

local function device_init(driver, device)
  log.info("<<---- Divoom ---->> device_init")
  initialized = true
  base_url = device.preferences.divoomIP

  device.profile.components['main']:emit_event(capability_cloud_channel.cloudChannel({ value = "Recommend Gallery" }))
  device.profile.components['main']:emit_event(capability_visualizer_channel.visualizerChannel({ value = 0 }))
  device.profile.components['main']:emit_event(capability_custom_channel.customChannel({ value = "First" }))
  refresh_handler(driver, device, null)
end

local function device_added (driver, device)
  log.info("<<---- Divoom ---->> device_added")
end

local function device_doconfigure (_, device)
  -- Nothing to do here!
end

local function device_removed(_, device)
  log.info("<<---- Divoom ---->> device_removed : ", device.id .. ": " .. device.device_network_id)
  initialized = false
end

local function device_driver_switched(driver, device, event, args)
  log.info("<<---- Divoom ---->> device_driver_switched")
end

local function shutdown_handler(driver, event)
  log.info("<<---- Divoom ---->> shutdown_handler")
end

local function device_info_changed (driver, device, event, args)
  log.info("<<---- Divoom ---->> device_info_changed")
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
  log.info("<<---- Divoom ---->> on_off_handler - command.component : ", command.component)
  log.info("<<---- Divoom ---->> on_off_handler - command.command : ", command.command)
  local on_off = (command.command == "off") and 0 or 1
  local payload = string.format('{"Command": "Channel/OnOffScreen", "OnOff": %d}', on_off)
  local status, response = request(payload);

  refresh_handler(driver, device, command)
end

local bright_handler = function(driver, device, command)
  log.info("<<---- Divoom ---->> bright_handler - command.component : ", command.component)
  log.info("<<---- Divoom ---->> bright_handler - command.args.level : ", command.args.level)
  local payload = string.format('{"Command": "Channel/SetBrightness", "Brightness": %s}', command.args.level)
  local status, response = request(payload);

  refresh_handler(driver, device, command)
end

local channel_handler = function(driver, device, command)
  log.info("<<---- Divoom ---->> channel_handler - command.component : ", command.component)
  log.info("<<---- Divoom ---->> channel_handler - command.args.value : ", command.args.value)
  local payload = string.format('{"Command": "Channel/SetIndex", "SelectIndex": %d}', command.args.value)
  local status, response = request(payload);

  refresh_handler(driver, device, command)
end

local cloud_channel_handler = function(driver, device, command)
  log.info("<<---- Divoom ---->> cloud_channel_handler - command.component : ", command.component)
  log.info("<<---- Divoom ---->> cloud_channel_handler - command.args.value : ", command.args.value)
  local payload = string.format('{"Command": "Channel/CloudIndex", "Index": %d}', command.args.value)
  local status, response = request(payload);

  if status then
    if command.args.value == "0" then
      cloudChannelValue = "Recommend Gallery"
    elseif command.args.value == "1" then
      cloudChannelValue = "Favourite"
    elseif command.args.value == "2" then
      cloudChannelValue = "Subscribe Artist"
    elseif command.args.value == "3" then
      cloudChannelValue = "Album"
    end

    device.profile.components['main']:emit_event(capability_cloud_channel.cloudChannel({ value = cloudChannelValue }))
    refresh_handler(driver, device, command)
  end
end

local visualizer_channel_handler = function(driver, device, command)
  log.info("<<---- Divoom ---->> visualizer_channel_handler - command.component : ", command.component)
  log.info("<<---- Divoom ---->> visualizer_channel_handler - command.args.value : ", command.args.value)
  local payload = string.format('{"Command": "Channel/SetEqPosition", "EqPosition": %d}', command.args.value)
  local status, response = request(payload);

  if status then
    device.profile.components['main']:emit_event(capability_visualizer_channel.visualizerChannel({ value = command.args.value }))
    refresh_handler(driver, device, command)
  end
end

local custom_channel_handler = function(driver, device, command)
  log.info("<<---- Divoom ---->> custom_channel_handler - command.component : ", command.component)
  log.info("<<---- Divoom ---->> custom_channel_handler - command.args.value : ", command.args.value)
  local payload = string.format('{"Command": "Channel/SetCustomPageIndex", "CustomPageIndex": %d}', command.args.value)
  local status, response = request(payload);

  if status then
    if status then
      if command.args.value == "0" then
        customChannelValue = "First"
      elseif command.args.value == "1" then
        customChannelValue = "Second"
      elseif command.args.value == "2" then
        customChannelValue = "Third"
      end
    end

    device.profile.components['main']:emit_event(capability_custom_channel.customChannel({ value = customChannelValue }))
    refresh_handler(driver, device, command)
  end
end

local message_handler = function(driver, device, command)
  log.info("<<---- Divoom ---->> message_handler - command.component : ", command.component)
  log.info("<<---- Divoom ---->> message_handler - command.args.value : ", command.args.value)

  local payload1 = string.format('{"Command":"Draw/ResetHttpGifId"}')
  local status1, response1 = request(payload1)

  local payload2 = string.format('{"Command":"Draw/SendHttpGif","PicNum":1,"PicWidth":64,"PicOffset":0,"PicID":1,"PicSpeed":10,"PicData":""}')
  local status2, response2 = request(payload2)

  local item1 = string.format(
      '{"TextId":1, "type":22,"x":0, "y":0, "dir":0, "font":112, "TextWidth":64, "Textheight":16, "speed":100, "TextString": "Sending Time: %s", "color":"#FF00000", "align":2}', os.date())
  local item2 = string.format(
      '{"TextId":2, "type":22,"x":0, "y":7, "dir":0, "font":2, "TextWidth":64, "Textheight":16, "speed":100, "TextString": "%s", "color":"#FFFFFF", "align":2}', command.args.value)
  local payload3 = string.format('{"Command":"Draw/SendHttpItemList", "ItemList":[%s,%s]}', item1, item2)

  local status3, response3 = request(payload3)
  -- Note: Draw/CommandList로 같이 보내면 작동이 잘 안됨

  log.info("<<---- Divoom ---->> message_handler - status : ", status3)
  if status1 and status2 and status3 then
    device.profile.components['system']:emit_event(capability_message.message({ value = "Sending Success" }))
  else
    device.profile.components['system']:emit_event(capability_message.message({ value = "Sending Fail" }))
  end

  refresh_handler(driver, device, command)
end

local lanDriver = Driver("lanDriver", {
  discovery = discovery_handler,
  lifecycle_handlers = {
    added = device_added,
    init = device_init,
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
    [capability_channel.ID] = {
      [capability_channel.commands.setChannel.NAME] = channel_handler,
    },
    [capability_cloud_channel.ID] = {
      [capability_cloud_channel.commands.setCloudChannel.NAME] = cloud_channel_handler,
    },
    [capability_visualizer_channel.ID] = {
      [capability_visualizer_channel.commands.setVisualizerChannel.NAME] = visualizer_channel_handler,
    },
    [capability_custom_channel.ID] = {
      [capability_custom_channel.commands.setCustomChannel.NAME] = custom_channel_handler,
    },
    [capability_message.ID] = {
      [capability_message.commands.setMessage.NAME] = message_handler,
    },
    [capabilities.switchLevel.ID] = {
      [capabilities.switchLevel.commands.setLevel.NAME] = bright_handler,
    },
  }
})

log.info('LAN-Divoom Started')
lanDriver:run()