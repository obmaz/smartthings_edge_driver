---- Zigbee Tuya Switch
----
---- Licensed under the Apache License, Version 2.0 (the "License");
---- you may not use this file except in compliance with the License.
---- You may obtain a copy of the License at
----
----     http://www.apache.org/licenses/LICENSE-2.0
----
---- Unless required by applicable law or agreed to in writing, software
---- distributed under the License is distributed on an "AS IS" BASIS,
---- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
---- See the License for the specific language governing permissions and
---- limitations under the License.

local IS_120SEC_ISSUE_FINGERPRINTS = {
  { mfr = "_TZ3000_fvh3pjaz", model = "TS0012" },
  { mfr = "_TZ3000_9hpxg80k", model = "TS0011" },
}

function write_attribute_function(device, cluster_id, attr_id, data_value)
  local write_body = write_attribute.WriteAttribute({
    write_attribute.WriteAttribute.AttributeRecord(attr_id, data_types.ZigbeeDataType(data_value.ID), data_value.value)})

  local zclh = zcl_messages.ZclHeader({
    cmd = data_types.ZCLCommandId(write_attribute.WriteAttribute.ID)
  })

  local addrh = messages.AddressHeader(
      zb_const.HUB.ADDR,
      zb_const.HUB.ENDPOINT,
      device:get_short_address(),
      device:get_endpoint(cluster_id.value),
      zb_const.HA_PROFILE_ID,
      cluster_id.value
  )

  local message_body = zcl_messages.ZclMessageBody({
    zcl_header = zclh,
    zcl_body = write_body
  })

  device:send(messages.ZigbeeMessageTx({
    address_header = addrh,
    body = message_body
  }))
end

function check_120sec_issue(device)
  for _, fingerprint in ipairs(IS_120SEC_ISSUE_FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      log.info("<<---- Moon ---->> is_120sec_issue : true / device.fingerprinted_endpoint_id :", device.fingerprinted_endpoint_id)

      --- Configure basic cluster, attributte 0x0099 to 0x1
      local cluster_id = {value = 0x0000}
      local attr_id = 0x0099
      local data_value = {value = 0x01, ID = 0x20}
      write_attribute_function(device, cluster_id, attr_id, data_value)
      log.info("<<---- Moon ---->> is_120sec_issue : true", device:pretty_print())
      return
    end
  end
  log.info("<<---- Moon ---->> is_120sec_issue : false", device:pretty_print())
end