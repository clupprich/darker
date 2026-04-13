defmodule Darker.Scheduler do
  use Quantum, otp_app: :darker

  import Crontab.CronExpression

  def load_schedule() do
    schedule = [
      {~e[30 5 * * *], :on, 4},
      {~e[30 6 * * *], :on, 44},
      {~e[00 18 * * *], :on, 4},
      {~e[30 19 * * *], :off, 4}
    ]

    delete_all_jobs()
    schedule |> Enum.each(&schedule_event/1)
  end

  defp schedule_event({cron, :on, brightness}) do
    Darker.Scheduler.add_job(
      {cron,
       fn ->
         Darker.Lights.on()
         Darker.Lights.set_brightness(brightness)
       end}
    )
  end

  defp schedule_event({cron, :off, brightness}) do
    Darker.Scheduler.add_job(
      {cron,
       fn ->
         Darker.Lights.off()
         Darker.Lights.set_brightness(brightness)
       end}
    )
  end
end
