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
        description: "Time interval (in s) after a state update is requested. If 0 then the state will not updated automatically."
        type: "number"
        default: 0
  }
  ZWayDimmer: {
    title: "ZWayDimmer config options"
    type: "object"
    properties:
      virtualDeviceId:
        description: "Virtual Device ID (call `curl http://HOSTNAME:8083/ZAutomation/api/v1/devices` for a list)"
        type: "string"
      interval:
        description: "Time interval (in s) after a state update is requested. If 0 then the state will not updated automatically."
        type: "number"
        default: 0
  }
  ZWayPowerSensor: {
    title: "ZWayPowerSensor config options"
    type: "object"
    properties:
      virtualDeviceId:
        description: "Virtual Device ID (call `curl http://HOSTNAME:8083/ZAutomation/api/v1/devices` for a list)"
        type: "string"
      interval:
        description: "Time interval (in s) after an update is requested."
        type: "number"
        default: 60
  }
  ZWayDoorWindowSensor: {
    title: "ZWayDoorWindowSensor config options"
    type: "object"
    properties:
      virtualDeviceId:
        description: "Virtual Device ID (call `curl http://HOSTNAME:8083/ZAutomation/api/v1/devices` for a list)"
        type: "string"
      interval:
        description: "Time interval (in s) after an update is requested."
        type: "number"
        default: 2
      inverted:
        description: "Sets 1 to opend and 0 to closed"
        type: "boolean"
        default: false
  }
  ZWayTemperatureSensor: {
    title: "ZWayTemperatureSensor config options"
    type: "object"
    properties:
      virtualDeviceId:
        description: "Virtual Device ID (call `curl http://HOSTNAME:8083/ZAutomation/api/v1/devices` for a list)"
        type: "string"
      interval:
        description: "Time interval (in s) after an update is requested."
        type: "number"
        default: 60
  }
  ZWayMotionSensor: {
    title: "ZWayMotionSensor config options"
    type: "object"
    properties:
      virtualDeviceId:
        description: "Virtual Device ID (call `curl http://HOSTNAME:8083/ZAutomation/api/v1/devices` for a list)"
        type: "string"
      interval:
        description: "Time interval (in s) after an update is requested."
        type: "number"
        default: 2
      inverted:
        description: "Sets 1 to motion and 0 to no motion"
        type: "boolean"
        default: false
  }
}