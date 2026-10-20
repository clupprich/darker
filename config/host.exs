import Config

# circuits_i2c's host stub only simulates a device at 0x10 on its test bus
config :darker, :dac, bus: "i2c-test-0", address: 0x10, channel: 0
