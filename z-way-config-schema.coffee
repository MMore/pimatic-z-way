module.exports = {
  title: "pimatic-z-way config options"
  type: "object"
  properties:
    hostname:
      description: "Hostname of the server that runs the z-way server (usually localhost)"
      type: "string"
      default: "localhost"
    username:
      description: "Username for your z-way webinterface"
      type: "string"
      default: "admin"
    password:
      description: "Password for your z-way webinterface"
      type: "string"
      default: ""
}
