defmodule Mix.Tasks.Summoners do
  @moduledoc "Prints list of opponents from most recent five matches and tracks those opponents' matches for an hour"
  @shortdoc "Summoner monitor"

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    [player, region] = args
    {:ok, _} = Application.ensure_all_started(:riot_summary)
    summoners = GenServer.call(RiotSummary, {:participants, player, region}, :infinity)
    Mix.Shell.IO.info("[#{Enum.join(summoners |> Enum.sort, ", ")}]")
    :timer.sleep(2 * 60 * 60 * 1_000)
  end
end
