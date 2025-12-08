defmodule Darker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Start the Telemetry supervisor
        DarkerWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: Darker.PubSub},
        # Start the Endpoint (http/https)
        DarkerWeb.Endpoint,
        # Start a worker by calling: Darker.Worker.start_link(arg)
        # {Darker.Worker, arg}
        {Darker.Lights, %{}},
        Darker.Scheduler
      ] ++ children(target())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Darker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Darker.Worker.start_link(arg)
      # {Darker.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Darker.Worker.start_link(arg)
      # {Darker.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:darker, :target)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DarkerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
