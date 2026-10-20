defmodule Darker.Scheduler do
  use Quantum, otp_app: :darker

  import Crontab.CronExpression

  @fade_duration :timer.minutes(2)

  def load_schedule() do
    delete_all_jobs()
    schedule() |> Enum.each(&schedule_event/1)

    replay_last_event()
  end

  defp schedule() do
    [
      {~e[30 5 * * *], :on, 5},
      {~e[30 6 * * *], :on, 30},
      {~e[00 18 * * *], :on, 5},
      {~e[30 22 * * *], :off, 0}
    ]
  end

  defp schedule_event({cron, _action, _brightness} = event) do
    Darker.Scheduler.add_job({cron, fn -> run_event(event) end})
  end

  # Nothing fires between boot and the next event, so restore the state the
  # most recent event would have left the lights in.
  defp replay_last_event() do
    now = DateTime.now!(config()[:timezone]) |> DateTime.to_naive()

    schedule()
    |> Enum.max_by(&previous_run(&1, now), NaiveDateTime)
    |> run_event()
  end

  defp previous_run({cron, _action, _brightness}, now) do
    {:ok, date} = Crontab.Scheduler.get_previous_run_date(cron, now)
    date
  end

  defp run_event({_cron, :on, brightness}) do
    Darker.Lights.on()
    Darker.Lights.fade_to(brightness, @fade_duration)
  end

  defp run_event({_cron, :off, brightness}) do
    Darker.Lights.fade_to(brightness, @fade_duration, then: :off)
  end
end
