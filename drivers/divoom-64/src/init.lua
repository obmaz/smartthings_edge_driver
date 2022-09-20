-- Edge libraries
local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local cosock = require "cosock"                 -- just for time
local socket = require "cosock.socket"          -- just for time
local json = require "dkjson"
local log = require "log"

local initialized = false

local function refresh_data()
    local device_list = divoom64Driver:get_devices()
    local request_url = device.preferences.divoom64_addr
    status, response = comms.issue_request(device, "GET", request_url)

    log.info('Status' + status)
    log.info('Response' + response)

    if status == true then
        --weathertable, pos, err = json.decode(weatherjson, 1, nil)
    end
end

local function handle_refresh(driver, device, command)
    log.info('Refresh requested')
    refresh_data()
end

local function device_init(driver, device)
    log.info("<<---- Moon ---->> device_init")
    initialized = true
end

local function device_added (driver, device)
    for key, value in pairs(device.profile.components) do
        log.info("<<---- Moon ---->> device_added - key : ", key)
        device.profile.components[key]:emit_event(capabilities.switch.switch.on())
    end
    device:refresh()
end

local function device_doconfigure (_, device)
    -- Nothing to do here!
    device:configure()
end

local function device_removed(_, device)
    log.warn(device.id .. ": " .. device.device_network_id .. "> removed")
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
    ---- Did preferences change?
    --if args.old_st_store.preferences then
    --  -- Examine each preference setting to see if it changed
    --  if args.old_st_store.preferences.divoom64_addr ~= device.preferences.divoom64_addr then
    --    if (validate_address(device.preferences.divoom64_addr)) then
    --      log.info('Proxy address is valid')
    --    else
    --      log.warn('Proxy address is INVALID')
    --    end
    --
    --  elseif args.old_st_store.preferences.autorefresh ~= device.preferences.autorefresh then
    --    if device.preferences.autorefresh == 'disabled' and periodic_timer then
    --      driver:cancel_timer(periodic_timer)
    --      periodic_timer = nil
    --    elseif device.preferences.autorefresh == 'enabled' then
    --      if periodic_timer then
    --        -- just in case
    --        driver:cancel_timer(periodic_timer)
    --      end
    --      periodic_timer = driver:call_on_schedule(device.preferences.refreshrate * 60, refresh_data, 'Refresh timer')
    --    end
    --
    --  elseif args.old_st_store.preferences.refreshrate ~= device.preferences.refreshrate then
    --    if device.preferences.autorefresh == 'enabled' then
    --      if periodic_timer then
    --        driver:cancel_timer(periodic_timer)
    --      end
    --      periodic_timer = driver:call_on_schedule(device.preferences.refreshrate * 60, refresh_data, 'Refresh timer')
    --    end
    --  end
    --else
    --  log.warn('Old preferences missing')
    --end
end

-- Create Weather Device
local function discovery_handler(driver, _, should_continue)
    if not initialized then
        log.info("Creating Web Request device")
        local MFG_NAME = 'SmartThings Community'
        local VEND_LABEL = 'Edge Divoom64'
        local MODEL = 'divoom64'
        local ID = 'divoom64' .. '_' .. socket.gettime()
        local PROFILE = 'LAN-Divoom64'

        -- Create master device
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

-- local zigbee_aqara_button_driver_template = {
local lanDriver = Driver("divoom64Driver", {
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
        capabilities.refresh
    },
    capability_handlers = {
        [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
        },
    }
})

log.info('LAN-Divoom64 Started')
lanDriver:run()