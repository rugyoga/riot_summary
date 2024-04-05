defmodule Mix.Tasks.Summoners do
  @moduledoc "Prints list of recent matches and tracks those oppoents for an hour"
  @shortdoc "Summoner monitor"

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    [player, region] = args
    {:ok, _} = Application.ensure_all_started(:riot_summary)
    RiotSummary.call(:participants, player, region)
  end
end
