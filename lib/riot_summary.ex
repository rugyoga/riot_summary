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
     participants |> Map.values |> Enum.map(&Riot.name/1),
     %{state | matches: matches, participants: participants, context: context}}
  rescue
    error -> {:stop, error, state}
  end

  @impl true
  def handle_info(:minute, state) do
    new_minute = state.minute+1
    IO.puts "Minute #{new_minute}"
    new_matches = MapSet.union(state.matches, new_matches(state))
    if new_minute == 60, do: System.halt(0)
    {:noreply, %{state | minute: new_minute, matches: new_matches}}
  end

  def last_match({puuid, info}, state) do
    case Riot.matches_by_puuid(puuid, state.context, [count: 1]) do
      %Req.Response{status: 200, body: [match]} ->
        if not MapSet.member?(state.matches, match) do
          IO.puts "Summoner #{Riot.name(info)} completed match #{match}"
          [match]
        else
          []
        end
      _ -> []
    end
  end

  def new_matches(state) do
    state.participants
    |> Enum.flat_map(&last_match(&1, state))
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
