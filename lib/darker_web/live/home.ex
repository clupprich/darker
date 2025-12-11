defmodule DarkerWeb.Home do
  use DarkerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Darker.PubSub, "brightness")

    brightness = Darker.Lights.get_brightness()
    status = Darker.Lights.get_status()

    socket =
      socket
      |> assign(:brightness, brightness)
      |> assign(:status, status)

    {:ok, socket}
  end

  @impl true
  def handle_event("inc_brightness", %{"delta" => delta}, socket) do
    current_level = Darker.Lights.get_brightness()
    Darker.Lights.set_brightness(current_level + delta)

    {:noreply, socket}
  end

  @impl true
  def handle_event("inc_brightness", _params, socket) do
    current_level = Darker.Lights.get_brightness()
    Darker.Lights.set_brightness(current_level + 1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("dec_brightness", %{"delta" => delta}, socket) do
    current_level = Darker.Lights.get_brightness()
    Darker.Lights.set_brightness(current_level - delta)

    {:noreply, socket}
  end

  @impl true
  def handle_event("dec_brightness", _params, socket) do
    current_level = Darker.Lights.get_brightness()
    Darker.Lights.set_brightness(current_level - 1)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{level: level}, socket) do
    {:noreply, assign(socket, :brightness, level)}
  end

  @impl true
  def handle_info(%{status: status}, socket) do
    {:noreply, assign(socket, :status, status)}
  end
end
