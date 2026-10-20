defmodule Darker.Dac do
  @moduledoc """
  Drives the DFRobot DFR0971 (GP8403) 0-10V DAC over I2C.

  Register layout taken from https://github.com/DFRobot/DFRobot_GP8403.
  """

  import Bitwise

  alias Circuits.I2C

  @output_range_register 0x01
  @output_range_10v 0x11
  @channel_registers %{0 => 0x02, 1 => 0x04}
  @max_code 4095
  @max_millivolts 10_000

  def open() do
    with {:ok, i2c} <- I2C.open(config(:bus)),
         :ok <- I2C.write(i2c, config(:address), <<@output_range_register, @output_range_10v>>) do
      {:ok, i2c}
    end
  end

  def millivolts(i2c, value) when value in 0..@max_millivolts do
    code = round(value / @max_millivolts * @max_code) <<< 4
    register = Map.fetch!(@channel_registers, config(:channel))

    I2C.write(i2c, config(:address), <<register, code::little-16>>)
  end

  defp config(key) do
    Application.fetch_env!(:darker, :dac) |> Keyword.fetch!(key)
  end
end
