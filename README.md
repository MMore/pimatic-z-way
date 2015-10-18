pimatic-z-way plugin
=======================

This is a pimatic plugin which allows you to control Z-Wave devices using [Z-Way](http://z-wave.me).

Configuration
-------------
You can load the plugin by editing your `config.json` to include:

    {
       "plugin": "z-way",
       "hostname": "10.10.7.46" // set hostname if necessary (localhost by default)
    }

Devices can be defined by adding them to the `devices` section in the config file.
Set the `class` attribute to one of the following classes. For example:

    {
      "class": "ZWaySwitch",
      "id": "fibaro_plug",
      "name": "Wall Plug",
      "virtualDeviceId": "ZWayVDev_zway_2-0-42",
      "interval": 0
    },
    {
      "class": "ZWayDimmer",
      "id": "fibaro_dimmer",
      "name": "Dimmer",
      "virtualDeviceId": "ZWayVDev_zway_2-0-44",
      "interval": 0
    },
    {
      "class": "ZWayPowerSensor",
      "id": "fibaro_power_sensor",
      "name": "Power Sensor",
      "virtualDeviceId": "ZWayVDev_zway_2-0-43"
    },
    {
      "class": "ZWayDoorWindowSensor",
      "id": "fibaro_window_sensor",
      "name": "Window Sensor",
      "virtualDeviceId": "ZWayVDev_zway_2-0-45"
    },
    {
      "class": "ZWayTemperatureSensor",
      "id": "fibaro_temp_sensor",
      "name": "Window Sensor",
      "virtualDeviceId": "ZWayVDev_zway_2-0-46"
    },
    {
      "class": "ZWayMotionSensor",
      "id": "fibaro_motion_sensor",
      "name": "Motion Sensor",
      "virtualDeviceId": "ZWayVDev_zway_2-0-47"
    }



Figure the `virtualDeviceId` out by calling `curl http://HOSTNAME:8083/ZAutomation/api/v1/devices`.
If the `interval` option is greater than 0 then the state of the device is updated automatically after the defined seconds. Sensors always should have a value greater than 0.

Authentication
--------------

Starting with Z-Way v2.0.1 authentication can become an [issue](https://github.com/Z-Wave-Me/zwave-smarthome/issues/22) for you. There must be a user that has access to your devices.

1. Go to http://HOSTNAME:8083/smarthome/
2. Assign your devices to room(s).
3. In User management allow the 'Local User' to access your rooms.
4. If you do not use the default 'localhost' as hostname, create a new anonymous user and allow him access to your rooms.
