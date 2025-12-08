defmodule Darker.Lights do
  use GenServer
  alias Darker.Pwm

  require Logger

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(state \\ %{}) do
    {:ok, state, {:continue, :init_lights}}
  end

  @impl GenServer
  def handle_continue(:init_lights, state) do
    :timer.sleep(5000)

    Logger.info("Initializing Lights")

    Pwm.export("0")
    Pwm.period(1_000_000)
    Pwm.duty_cycle(77_250)
    Pwm.enable("1")

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:get_brightness, _from, state) do
    level =
      Pwm.duty_cycle()
      |> String.trim()
      |> String.to_integer()
      |> duty_cycle_to_level()

    {:reply, level, state}
  end

  @impl GenServer
  def handle_cast({:set_brightness, level}, state) do
    duty_cycle = level_to_duty_cycle(level) |> Integer.to_string()

    Logger.info("Setting brightness to #{level}% (duty_cycle: #{duty_cycle})")

    Pwm.duty_cycle(duty_cycle)

    Phoenix.PubSub.broadcast(Darker.PubSub, "brightness", %{level: level})

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:enable, state) do
    Logger.info("Enabling Lights")

    Pwm.enable("1")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:disable, state) do
    Logger.info("Disabling Lights")

    Pwm.enable("0")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:on, state) do
    Logger.info("Turn lights on")

    Circuits.GPIO.write_one("GPIO26", 1)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:off, state) do
    Logger.info("Turn lights off")

    Circuits.GPIO.write_one("GPIO26", 0)

    {:noreply, state}
  end

  def get_brightness() do
    GenServer.call(__MODULE__, :get_brightness)
  end

  def set_brightness(level) do
    GenServer.cast(__MODULE__, {:set_brightness, level})
  end

  def enable() do
    GenServer.cast(__MODULE__, :enable)
  end

  def disable() do
    GenServer.cast(__MODULE__, :disable)
  end

  def on() do
    GenServer.cast(__MODULE__, :on)
  end

  def off() do
    GenServer.cast(__MODULE__, :off)
  end

  defp duty_cycle_to_level(duty_cycle) do
    max = 80_250
    min = 77_250

    level =
      case duty_cycle do
        duty when duty >= max -> 100
        duty when duty <= min -> 0
        duty -> round((duty - min) / (max - min) * 100)
      end

    level
  end

  defp level_to_duty_cycle(level) do
    max = 80_250
    min = 77_250

    round(level / 100 * (max - min) + min)
  end
end
