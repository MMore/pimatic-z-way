module.exports = {
  title: "pimatic-z-way device config options"
  ZWaySwitch: {
    title: "ZWaySwitch config options"
    type: "object"
    properties:
      virtualDeviceId:
        description: "Virtual Device ID (call `curl http://HOSTNAME:8083/ZAutomation/api/v1/devices` for a list)"
        type: "string"
      interval:
        description: "Time interval in s after a state update is requested. If 0 then the state will not updated automatically."
        type: "number"
        default: 0
  }
}
