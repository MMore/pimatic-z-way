module.exports = (env) ->

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take
  # a look at the dependencies section in pimatics package.json
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  rp = require 'request-promise'

  class ZWayPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins`
    #     section of the config.json file
    #
    #
    init: (app, @framework, @config) =>
      env.logger.info("initialized pimatic-z-way with hostname " + @config.hostname)

      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("ZWaySwitch", {
        configDef: deviceConfigDef.ZWaySwitch,
        createCallback: (config) => new ZWaySwitch(config)
      })
      @framework.deviceManager.registerDeviceClass("ZWayDimmer", {
        configDef: deviceConfigDef.ZWayDimmer,
        createCallback: (config) => new ZWayDimmer(config)
      })
      @framework.deviceManager.registerDeviceClass("ZWayPowerSensor", {
        configDef: deviceConfigDef.ZWayPowerSensor,
        createCallback: (config) => new ZWayPowerSensor(config)
      })

    sendCommand: (virtualDeviceId, command) ->
      address = "http://" + @config.hostname + ":8083/ZAutomation/api/v1/devices/" + virtualDeviceId + "/command/" + command
      env.logger.debug("sending command " + address)
      return rp(address)

    getDeviceDetails: (virtualDeviceId) ->
      address = "http://" + @config.hostname + ":8083/ZAutomation/api/v1/devices/" + virtualDeviceId
      env.logger.debug("fetching device details " + address)
      return rp(address).then(JSON.parse)


  class ZWaySwitch extends env.devices.PowerSwitch

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId

      updateValue = =>
        if @config.interval > 0
          @getState().finally( =>
            setTimeout(updateValue, @config.interval * 1000)
          )

      super()
      updateValue()

    changeStateTo: (state) ->
      if @state is state then return
      command = if state then "on" else "off"
      return plugin.sendCommand(@virtualDeviceId, command).then( =>
        @_setState(state)
      ).catch( (e) =>
        env.logger.error("state change failed with " + e.message)
      )

    getState: () ->
      return plugin.getDeviceDetails(@virtualDeviceId).then( (json) =>
        state = json.data.metrics.level
        @_setState(state == "on")
        return @_state
      ).catch( (e) =>
        env.logger.error("state update failed with " + e.message)
        return @_state
      )


  class ZWayDimmer extends env.devices.DimmerActuator

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId

      updateValue = =>
        if @config.interval > 0
          @getDimlevel().finally( =>
            setTimeout(updateValue, @config.interval * 1000)
          )

      super()
      updateValue()

    changeDimlevelTo: (level) ->
      if @_dimlevel is level then return
      return plugin.sendCommand(@virtualDeviceId, "exact?level=#{level}").then( =>
        @_setDimlevel(level)
      ).catch( (e) =>
        env.logger.error("dim level change failed with #{e.message}")
      )

    getDimlevel: () ->
      return plugin.getDeviceDetails(@virtualDeviceId).then( (json) =>
        level = json.data.metrics.level
        @_setDimlevel(level)
        return @_dimlevel
      ).catch( (e) =>
        env.logger.error("dim level update failed with #{e.message}")
        return @_dimlevel
      )


  class ZWayPowerSensor extends env.devices.Sensor

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId

      @attributes = {}
      sensor = "power"
      @attributes[sensor] = {}
      @attributes[sensor].description = "Current Power Consumption"
      @attributes[sensor].type = "number"

      getter = ( =>
        return plugin.getDeviceDetails(@virtualDeviceId).then( (json) =>
          val = json.data.metrics.level
          unit = json.data.metrics.scaleTitle
          @attributes[sensor].unit = unit
          return val
        )
      )

      @_createGetter(sensor, getter)
      setInterval( ( =>
        getter().then( (value) =>
          @emit sensor, value
        ).catch( (error) =>
          env.logger.error("error updating sensor value for #{sensor}", error.message)
        )
      ), @config.interval * 1000)
      super()


  plugin = new ZWayPlugin
  return plugin
