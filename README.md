# Nerves + LiveView Example

This example shows a Nerves Project with a Phoenix server embedded in the same
application.  In contrast to a [poncho
project](https://embedded-elixir.com/post/2017-05-19-poncho-projects/), there is
only one application supervision tree containing the Phoenix Endpoint and any
processes running on the device.

## Configuration

The order of configuration is loaded in a specific order:

* `config.exs`
* `host.exs` or `target.exs`  based on `MIX_TARGET`
* `prod.exs`, `dev.exs`, or `test.exs` based on `MIX_ENV`
* `runtime.exs` at runtime

To make configuration slightly more straightforward, the application is run with
`MIX_ENV=prod` when on the device.  Therefore, the configuration for Phoenix on
the target device is in the `prod.exs` config file.

## Developing

You can start the application just like any Phoenix project:

```bash
iex -S mix phx.server
```

## Flashing to a Device

You can burn the first image with the following commands:

```bash
# If you want to enable wifi:
# export NERVES_SSID="NetworkName" && export NERVES_PSK="password"
MIX_ENV=prod MIX_TARGET=host mix do deps.get, assets.deploy
MIX_ENV=prod MIX_TARGET=rpi4 mix do deps.get, firmware, burn
```

Once the image is running on the device, the following will build and update the
firmware over ssh.

```bash
# If you want to enable wifi:
# export NERVES_SSID="NetworkName" && export NERVES_PSK="password"
MIX_ENV=prod MIX_TARGET=host mix do deps.get, assets.deploy
MIX_ENV=prod MIX_TARGET=rpi4 mix do deps.get, firmware, upload darker.local
```

## Network Configuration

The network and WiFi configuration are specified in the `target.exs` file.  In
order to specify the network name and password, they must be set as environment
variables `NERVES_SSID` `NERVES_PSK` at runtime.

If they are not specified, a warning will be printed when building firmware,
which either gives you a chance to stop the build and add the environment
variables or a clue as to why you are no longer able to access the device over
WiFi.

## Control

```elixir
File.write!("/sys/class/pwm/pwmchip0/export", "0")

File.write!("/sys/class/pwm/pwmchip0/pwm0/period", "1000000")
# Linear
File.write!("/sys/class/pwm/pwmchip0/pwm0/duty_cycle", "772700")
# Logarithmic
File.write!("/sys/class/pwm/pwmchip0/pwm0/duty_cycle", "77250")

File.write!("/sys/class/pwm/pwmchip0/pwm0/enable", "1")
File.write!("/sys/class/pwm/pwmchip0/pwm0/enable", "0")

delta = 1000000 - 77250
steps = 1000

for i <- 0..steps do
  duty_cycle = round(1000000 - ((delta / steps) * i))
  IO.puts("Duty cycle: #{duty_cycle}")
  File.write!("/sys/class/pwm/pwmchip0/pwm0/duty_cycle", "#{duty_cycle}")
  :timer.sleep(10)
end

```

```elixir
{:ok, gpio} = Circuits.GPIO.open("GPIO26", :output)
Circuits.GPIO.write(gpio, 1)
Circuits.GPIO.write(gpio, 0)
Circuits.GPIO.close(gpio)

Circuits.GPIO.write_one("GPIO26", 1)
```

```elixir
import Crontab.CronExpression

Darker.Scheduler.add_job({~e[* * * * *], fn -> Circuits.GPIO.write_one("GPIO26", 1) end})
```

```
~e[5 30 * * *],:on,3
~e[6 30 * * *],:on,43
~e[18 30 * * *],:on,3
~e[21 30 * * *],:off,3
```
