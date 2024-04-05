defmodule RiotSummary do
  @moduledoc """
  Documentation for `RiotSummary`.
  """
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], name: name)
  end

  @impl true
  def init(_) do
    :timer.send_interval(60_000, :minute)
    {:ok, %{minute: 0, participants: %{}, matches: MapSet.new, context: %{region: "na1", continent: "americas"}}}
  end

  @impl true
  def handle_call({:participants, player, region}, _from, state) do
    context = %{region: region, continent: Riot.continent(region)}
    matches = recent(player, context)
    participants = all_participants(matches, context)
    {:reply,
     participants |> Map.values |> Enum.map(& &1.name),
     %{state | matches: matches, participants: participants, context: context}}
  rescue
    error -> {:stop, error, state}
  end

  @impl true
  def handle_info(:minute, state) do
    new_minute = state.minute+1
    if new_minute == 60 do
      {:stop, "Mission completed", state}
    else
      IO.puts "Minute #{new_minute}"
      new_matches = MapSet.union(state.matches, new_matches(state))
      {:noreply, %{state | minute: new_minute, matches: new_matches}}
    end
  end

  def new_matches(%{context: context, matches: matches, participants: participants}) do
    participants
    |> Enum.flat_map(
      fn {puuid, info} ->
        case Riot.matches_by_puuid(puuid, context, [count: 1]) do
          %Req.Response{status: 200, body: [match]} ->
            if MapSet.member?(matches, match) do
              []
            else
              IO.puts "Summoner #{info.name} completed match #{match}"
              [match]
            end
          _ -> []
        end
      end
    )
    |> MapSet.new
  end

  def recent(name, context) do
    name
    |> Riot.player_by_name(context)
    |> then(& &1.body.puuid)
    |> Riot.matches_by_puuid(context, [count: 5])
    |> then(& &1.body)
    |> MapSet.new
  end

  def all_participants(matches, context) do
    matches
    |> Enum.flat_map(fn match -> Riot.match(match, context).body.metadata.participants end)
    |> Enum.uniq()
    |> Enum.map(fn p -> {p, Riot.player_by_puuid(p, context).body} end)
    |> Map.new
  end
end
