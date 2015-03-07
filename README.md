pimatic-z-way plugin
=======================

This is a pimatic plugin which allows you to control Z-Wave devices using [Z-Way](http://z-wave.me).

Configuration
-------------
You can load the plugin by editing your `config.json` to include:

    {
       "plugin": "z-way"
       "hostname": "10.10.7.46" // set hostname if necessary (localhost by default)
    }

Devices can be defined by adding them to the `devices` section in the config file.
Set the `class` attribute to `ZWaySwitch`. For example:

    {
      "class": "ZWaySwitch",
      "id": "fibaro_plug",
      "name": "WallPlug",
      "virtualDeviceId": "ZWayVDev_zway_2-0-42",
      "interval": "0"
    }

Figure the `virtualDeviceId` out by calling `curl http://HOSTNAME:8083/ZAutomation/api/v1/devices`.
If the `interval` option is greater than 0 then the state of the device is updated automatically after X seconds.
