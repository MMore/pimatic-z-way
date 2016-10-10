module.exports = (env) ->

# ###require modules included in pimatic
# To require modules that are included in pimatic use `env.require`. For available packages take
# a look at the dependencies section in pimatics package.json
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  rp = env.require 'request-promise'

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
      @options =
        'json': true
        'simple': true
        'resolveWithFullResponse': false
        'jar': true

      @authenticated = false

      env.logger.debug "registering devices"

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
      @framework.deviceManager.registerDeviceClass("ZWayLuminiscenceSensor", {
        configDef: deviceConfigDef.ZWayLuminiscenceSensor,
        createCallback: (config) => new ZWayLuminiscenceSensor(config)
      })
      @framework.deviceManager.registerDeviceClass("ZWayDoorWindowSensor", {
        configDef: deviceConfigDef.ZWayDoorWindowSensor,
        createCallback: (config) => new ZWayDoorWindowSensor(config)
      })
      @framework.deviceManager.registerDeviceClass("ZWayTemperatureSensor", {
        configDef: deviceConfigDef.ZWayTemperatureSensor,
        createCallback: (config) => new ZWayTemperatureSensor(config)
      })
      @framework.deviceManager.registerDeviceClass("ZWayMotionSensor", {
        configDef: deviceConfigDef.ZWayMotionSensor,
        createCallback: (config) => new ZWayMotionSensor(config)
      })
      @framework.deviceManager.registerDeviceClass("ZWayShutterController", {
        configDef: deviceConfigDef.ZWayShutterController,
        createCallback: (config) => new ZWayShutterController(config)
      })

    sendCommand: (virtualDeviceId, command) ->
      address = "http://" + @config.hostname + ":8083/ZAutomation/api/v1/devices/" + virtualDeviceId + "/command/" + command
      env.logger.debug("sending command " + address)

      @logIn()
      .then ()=>
        commandAnswer = rp address, @options
        .then (json) =>
          try
            #needed because json could contain circular reference
            env.logger.debug "received command answer:#{JSON.stringify(json)}"
          catch e
            env.logger.debug "received command answer"

          return json

        return commandAnswer
      .catch (error)=>
        if error.message.match(401)
          env.logger.error ("reseting authentication")
          @authenticated = false

    getDeviceDetails: (virtualDeviceId) ->
      address = "http://" + @config.hostname + ":8083/ZAutomation/api/v1/devices/" + virtualDeviceId

      @logIn()
      .then ()=>
        deviceDetails = rp address, @options
        .then (json) =>
          try
            # needed because json could contain circular reference
            env.logger.debug "received device details:#{JSON.stringify(json)}"
          catch e
            env.logger.debug "received device details"

          return json

        return deviceDetails
      .catch (error)=>
        if error.message.match(401)
          env.logger.error ("reseting authentication")
          @authenticated = false



    logIn: ()->
      if @authenticated then return Promise.resolve()

      address = "http://" + @config.hostname + ":8083/ZAutomation/api/v1/login"
      env.logger.debug("logging in " + address)

      authOptions = JSON.parse(JSON.stringify(@options));

      authOptions.body =
        'login': @config.username
        'password': @config.password

      authOptions.method = 'POST'

      loginRequest = rp address, authOptions
      .then (json) =>
        env.logger.debug "login success: #{json}"
        @authenticated = true
        return json
      .catch (error) =>
        env.logger.debug "error logging in: #{error}"

      return loginRequest

    sleep: (ms) ->
      start = new Date().getTime()
      continue while new Date().getTime() - start < ms


  class ZWaySwitch extends env.devices.PowerSwitch

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId

      updateValue = =>
        if @config.interval > 0
          @getState().finally( =>
            @_updateInterval = setTimeout(updateValue, @config.interval * 1000)
          )

      super()
      updateValue()

    changeStateTo: (state) ->
      if @state is state then return Promise.resolve()
      command = if state then "on" else "off"
      return plugin.sendCommand(@virtualDeviceId, command).then( =>
        @_setState(state)
        #2 seconds to wait before the switch status is read
        plugin.sleep 2000
        #get switch status from zway
        @getState()
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

    destroy: ->
      clearTimeout(@_updateInterval)
      super()


  class ZWayDimmer extends env.devices.DimmerActuator

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId

      updateValue = =>
        if @config.interval > 0
          @getDimlevel().finally( =>
            @_updateInterval = setTimeout(updateValue, @config.interval * 1000)
          )

      super()
      updateValue()

    changeDimlevelTo: (level) ->
      if @_dimlevel is level then return Promise.resolve()
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

    destroy: ->
      clearTimeout(@_updateInterval)
      super()

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
      @_updateInterval = setInterval( ( =>
        getter().then( (value) =>
          @emit sensor, value
        ).catch( (error) =>
          env.logger.error("error updating sensor value for #{sensor}", error.message)
        )
      ), @config.interval * 1000)
      super()

    destroy: ->
      clearTimeout(@_updateInterval)
      super()

  class ZWayDoorWindowSensor extends env.devices.ContactSensor

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId
      @_contact = lastState?.contact?.value or false

      @readContactValue()
      @_updateInterval = setInterval( ( => @readContactValue().catch( (error) =>
        env.logger.error("error updating sensor value ", error.message)
      )
      ), @config.interval * 1000)
      super()

    setContactValue: (value) ->
      assert value is 1 or value is 0
      state = (if value is 1 then true else false)
      if @config.inverted then state = not state
      @_setContact state

    readContactValue: ->
      return plugin.getDeviceDetails(@virtualDeviceId).then( (json) =>
        val = json.data.metrics.level
        value = 0
        if val is "on" then value = 1
        @setContactValue value
        return @_contact
      )

    getContact: () -> if @_contact? then Promise.resolve(@_contact) else @readContactValue()

    destroy: ->
      clearTimeout(@_updateInterval)
      super()

  class ZWayTemperatureSensor extends env.devices.TemperatureSensor
    temperature: null

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId
      sensor = "temperature"

      getter = ( =>
        return plugin.getDeviceDetails(@virtualDeviceId).then( (json) =>
          val = json.data.metrics.level
          unit = json.data.metrics.scaleTitle
          @attributes[sensor].unit = unit
          return val
        )
      )

      @_createGetter(sensor, getter)
      @_updateInterval = setInterval( ( =>
        getter().then( (value) =>
          @emit sensor, value
        ).catch( (error) =>
          env.logger.error("error updating sensor value for #{sensor}", error.message)
        )
      ), @config.interval * 1000)
      super()

    destroy: ->
      clearTimeout(@_updateInterval)
      super()

  class ZWayLuminiscenceSensor extends env.devices.Sensor

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId

      @attributes = {}
      sensor = "luminiscence"
      @attributes[sensor] = {}
      @attributes[sensor].description = "Current Luminiscence"
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

    destroy: ->
      clearTimeout(@_updateInterval)
      super()

  class ZWayMotionSensor extends env.devices.PresenceSensor

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @virtualDeviceId = @config.virtualDeviceId
      @_presence = lastState?.presence?.value or false

      @readPresenceValue()
      @_updateInterval = setInterval( ( => @readPresenceValue().catch( (error) =>
        env.logger.error("error updating sensor value ", error.message)
      )
      ), @config.interval * 1000)
      super()

    setPresenceValue: (value) ->
      assert value is 1 or value is 0
      state = (if value is 1 then true else false)
      if @config.inverted then state = not state
      @_setPresence state

    readPresenceValue: ->
      return plugin.getDeviceDetails(@virtualDeviceId).then( (json) =>
        val = json.data.metrics.level
        value = 0
        if val is "on" then value = 1
        @setPresenceValue value
        return @_presence
      )

    destroy: ->
      clearTimeout(@_updateInterval)
      super()

  class ZWayShutterController extends env.devices.ShutterController

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @_position = lastState?.position?.value or 'stopped'
      @virtualDeviceId = @config.virtualDeviceId

      updateValue = =>
        if @config.interval > 0
          @getPosition().finally( =>
            @_updateInterval = setTimeout(updateValue, @config.interval * 1000)
          )

      super()
      updateValue()

    stop: ->
      if @_position is 'stopped' then return Promise.resolve()
      return plugin.sendCommand(@virtualDeviceId, 'stop').then( =>
        @_lastSendTime = new Date().getTime()
        @_setPosition('stopped')
        @emit "position", @_position
      ).catch( (e) =>
        env.logger.error("stop failed with " + e.message)
      )

    moveUp: ->
      if @_position is 'up' then return Promise.resolve()
      return plugin.sendCommand(@virtualDeviceId, 'exact?level=99').then( =>
        @_lastSendTime = new Date().getTime()
        @_setPosition('up')
        @emit "position", @_position
      ).catch( (e) =>
        env.logger.error("move up failed with " + e.message)
      )

    moveDown: ->
      if @_position is 'down' then return Promise.resolve()
      return plugin.sendCommand(@virtualDeviceId, 'exact?level=0').then( =>
        @_lastSendTime = new Date().getTime()
        @_setPosition('down')
        @emit "position", @_position
      ).catch( (e) =>
        env.logger.error("move down failed with " + e.message)
      )

    moveToPosition: (position) ->
      if position is @_position then return Promise.resolve()
      if  position is 'stopped' then return @stop()
      else
        if position is 'up' then return @moveUp()
        else
          if position is 'down' then return @moveDown()

    getPosition: () ->
      return plugin.getDeviceDetails(@virtualDeviceId).then( (json) =>
        level = json.data.metrics.level
        if level is 0 then positionTemp = 'down'
        else
          if level is 99 then positionTemp = 'up'
          else
            positionTemp = 'stopped'

        @_setPosition(positionTemp)
        @emit "position", @_position
        return @_position
      ).catch( (e) =>
        env.logger.error("position update failed with #{e.message}")
        return @_dimlevel
      )

    destroy: ->
      clearTimeout(@_updateInterval)
      super()

  plugin = new ZWayPlugin
  return plugin
