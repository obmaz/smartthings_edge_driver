local test = require "integration_test"
local t_utils = require "integration_test.utils"
local clusters = require "st.zigbee.zcl.clusters"
local LevelControlCluster = clusters.LevelControlCluster
local capabilities = require "st.capabilities"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"

local mock_simple_device = test.mock_device.build_test_zigbee_device({ profile = t_utils.get_profile_definition("zigbee-tuya-switch-3") })
test.mock_device.add_test_device(mock_simple_device)

test.register_message_test(
    "Capability command setLevel should be handled",
    {
      {
        channel = "capability",
        direction = "receive",
        message = { mock_simple_device.id, { capability = "switchLevel", command = "setLevel", args = { 57, 0 } } }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = { mock_simple_device.id, LevelControlCluster.commands.client.MoveToLevelWithOnOff(mock_simple_device,
            math.floor(57 * 0xFE / 100),
            0) }
      }
    }
)

test.run_registered_tests()
