defmodule Darker.Lights do
  use GenServer
  alias Darker.Dac

  require Logger

  @fade_step_interval 100

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

    {:noreply, Map.merge(state, %{i2c: i2c, level: 0, millivolts: 0, status: :off, fade: nil})}
  end

  @impl GenServer
  def handle_call(:get_brightness, _from, state) do
    {:reply, state.level, state}
  end

  # Reading GPIO26 back would reopen it as an input and may release the relay,
  # so report the last state we wrote instead.
  @impl GenServer
  def handle_call(:get_status, _from, state) do
    {:reply, state.status, state}
  end

  @impl GenServer
  def handle_cast({:set_brightness, level}, state) do
    level = clamp(level)

    Logger.info("Setting brightness to #{level}% (#{level_to_millivolts(level)} mV)")

    state = %{state | fade: nil} |> write_millivolts(level_to_millivolts(level))

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:fade_to, level, duration, opts}, state) do
    level = clamp(level)
    to = level_to_millivolts(level)

    Logger.info(
      "Fading brightness from #{state.level}% to #{level}% over #{div(duration, 1000)}s"
    )

    fade = %{
      ref: make_ref(),
      from: state.millivolts,
      to: to,
      started_at: System.monotonic_time(:millisecond),
      duration: if(state.millivolts == to, do: 0, else: duration),
      then: Keyword.get(opts, :then)
    }

    send(self(), {:fade_step, fade.ref})

    {:noreply, %{state | fade: fade}}
  end

  @impl GenServer
  def handle_cast(:on, state) do
    {:noreply, switch(state, :on)}
  end

  @impl GenServer
  def handle_cast(:off, state) do
    {:noreply, switch(state, :off)}
  end

  @impl GenServer
  def handle_info({:fade_step, ref}, %{fade: %{ref: ref} = fade} = state) do
    elapsed = System.monotonic_time(:millisecond) - fade.started_at
    progress = if fade.duration == 0, do: 1.0, else: min(elapsed / fade.duration, 1.0)

    state = write_millivolts(state, round(fade.from + (fade.to - fade.from) * progress))

    if progress < 1.0 do
      Process.send_after(self(), {:fade_step, ref}, @fade_step_interval)
      {:noreply, state}
    else
      Logger.info("Fade finished at #{state.level}%")
      state = %{state | fade: nil}
      {:noreply, if(fade.then, do: switch(state, fade.then), else: state)}
    end
  end

  # A manual change or a newer fade replaced this one.
  @impl GenServer
  def handle_info({:fade_step, _ref}, state) do
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

  def fade_to(level, duration, opts \\ []) do
    GenServer.cast(__MODULE__, {:fade_to, level, duration, opts})
  end

  def on() do
    GenServer.cast(__MODULE__, :on)
  end

  def off() do
    GenServer.cast(__MODULE__, :off)
  end

  defp switch(state, status) do
    Logger.info("Turn lights #{status}")

    Circuits.GPIO.write_one("GPIO26", if(status == :on, do: 1, else: 0))

    Phoenix.PubSub.broadcast(Darker.PubSub, "status", %{status: status})

    %{state | status: status}
  end

  defp write_millivolts(state, millivolts) do
    :ok = Dac.millivolts(state.i2c, millivolts)

    level = round(millivolts / 100)

    if level != state.level do
      Phoenix.PubSub.broadcast(Darker.PubSub, "brightness", %{level: level})
    end

    %{state | millivolts: millivolts, level: level}
  end

  defp clamp(level), do: level |> max(0) |> min(100)

  # The dimmer applies its own (logarithmic) curve, so map linearly onto 0-10V.
  defp level_to_millivolts(level) do
    level * 100
  end
end
