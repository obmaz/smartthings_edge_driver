local test = require "integration_test"
local t_utils = require "integration_test.utils"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
--zcl_clusters.OnOff.attributes.OnOff

local mock_device = test.mock_device.build_test_zigbee_device(
    {
      profile = t_utils.get_profile_definition("zigbee-tuya-switch-3.yaml"),
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "_TZ3000_7hp93xpr",
          model = "ts0002",
          server_clusters = { 0x0000, 0x0001, 0x0003, 0x000F, 0x0020, 0x0402, 0x0500, 0xFC02 }
        }
      }
    }
)
zigbee_test_utils.prepare_zigbee_env_info()

local function test_init()
  test.mock_device.add_test_device(mock_device)
  zigbee_test_utils.init_noop_health_check_timer()
end

test.set_test_init_function(test_init)

test.register_message_test(
    "Switch",
    {
      {
        channel = "device_lifecycle",
        direction = "receive",
        message = { mock_device.id, "added" }
      },
      --{
      --  channel = "capability",
      --  direction = "send",
      --  message = mock_device:generate_test_message("main", capabilities.switch.switch.on())
      --}
    }
)

test.run_registered_tests()