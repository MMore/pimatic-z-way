module.exports = (env) ->

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take
  # a look at the dependencies section in pimatics package.json

  Promise = env.require 'bluebird'

  assert = env.require 'cassert'

  # Include you own depencies with nodes global require function:
  #
  #     someThing = require 'someThing'
  #
  rp = require 'request-promise'

  # ###MyPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
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
        createCallback: (config) => new ZWaySwitch(config, @config.hostname)
      })

  class ZWaySwitch extends env.devices.PowerSwitch

    constructor: (@config, hostname) ->
      @name = @config.name
      @id = @config.id
      @virtualDeviceId = @config.virtualDeviceId
      @hostname = hostname

      updateValue = =>
        if @config.interval > 0
          @getState().finally( =>
            setTimeout(updateValue, @config.interval * 1000)
          )

      super()
      updateValue()

    changeStateTo: (state) ->
      command = if state then "on" else "off"
      address = "http://" + @hostname + ":8083/ZAutomation/api/v1/devices/" + @virtualDeviceId + "/command/" + command
      console.log("trigger " + address)
      if @state is state then return
      return rp(address).then(console.dir).then( =>
        @_setState(state)
      )

    getState: () ->
      address = "http://" + @hostname + ":8083/ZAutomation/api/v1/devices/" + @virtualDeviceId
      return rp(address).then(JSON.parse).then( (json) =>
        state = json.data.metrics.level
        @_setState(state == "on")
        return @_state
      ).catch( (e) =>
        env.logger.error("state update failed with " + e.message)
        return @_state
      )


  plugin = new ZWayPlugin
  return plugin
