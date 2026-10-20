defmodule Darker.Lights do
  use GenServer
  alias Darker.Dac

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

    {:ok, i2c} = Dac.open()
    :ok = Dac.millivolts(i2c, level_to_millivolts(0))

    {:noreply, Map.merge(state, %{i2c: i2c, level: 0})}
  end

  @impl GenServer
  def handle_call(:get_brightness, _from, state) do
    {:reply, state.level, state}
  end

  @impl GenServer
  def handle_call(:get_status, _from, state) do
    # Circuits.GPIO.read("GPIO26") do
    status =
      case Circuits.GPIO.read_one("GPIO26") do
        1 -> :on
        0 -> :off
        _ -> :unknown
      end

    {:reply, status, state}
  end

  @impl GenServer
  def handle_cast({:set_brightness, level}, state) do
    level = level |> max(0) |> min(100)
    millivolts = level_to_millivolts(level)

    Logger.info("Setting brightness to #{level}% (#{millivolts} mV)")

    :ok = Dac.millivolts(state.i2c, millivolts)

    Phoenix.PubSub.broadcast(Darker.PubSub, "brightness", %{level: level})

    {:noreply, %{state | level: level}}
  end

  @impl GenServer
  def handle_cast(:on, state) do
    Logger.info("Turn lights on")

    Circuits.GPIO.write_one("GPIO26", 1)

    Phoenix.PubSub.broadcast(Darker.PubSub, "status", %{status: :on})

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:off, state) do
    Logger.info("Turn lights off")

    Circuits.GPIO.write_one("GPIO26", 0)

    Phoenix.PubSub.broadcast(Darker.PubSub, "status", %{status: :off})

    {:noreply, state}
  end

  def get_brightness() do
    GenServer.call(__MODULE__, :get_brightness)
  end

  def get_status() do
    GenServer.call(__MODULE__, :get_status)
  end

  def set_brightness(level) do
    GenServer.cast(__MODULE__, {:set_brightness, level})
  end

  def on() do
    GenServer.cast(__MODULE__, :on)
  end

  def off() do
    GenServer.cast(__MODULE__, :off)
  end

  # The dimmer applies its own (logarithmic) curve, so map linearly onto 0-10V.
  defp level_to_millivolts(level) do
    level * 100
  end
end
