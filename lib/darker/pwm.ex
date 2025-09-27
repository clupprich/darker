defmodule Darker.Pwm do
  def export(value) when is_binary(value) do
    File.write(base_path() <> "/export", value)
  end

  def period(value) when is_integer(value) do
    File.write(base_path() <> "/pwm0/period", value |> Integer.to_string())
  end

  def duty_cycle() do
    File.read!(base_path() <> "/pwm0/duty_cycle")
  end

  def duty_cycle(value) when is_integer(value) do
    duty_cycle(value |> Integer.to_string())
  end

  def duty_cycle(value) when is_binary(value) do
    File.write(base_path() <> "/pwm0/duty_cycle", value)
  end

  def enable(value) when is_binary(value) do
    File.write(base_path() <> "/pwm0/enable", value)
  end

  defp base_path do
    Application.fetch_env!(:darker, :pwm_base_path)
  end
end
