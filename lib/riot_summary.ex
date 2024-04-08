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
    :timer.send_interval(60 * 1_000, :minute)
    :timer.send_interval(((61 * 60) - 1) * 1_000, :hour)
    {:ok, %{minute: 0, participants: %{}, matches: MapSet.new, context: %{region: "na1", continent: "americas"}}}
  end

  @impl true
  def handle_call({:participants, player, region}, _from, state) do
    context = %{region: region, continent: Riot.continent(region)}
    matches = recent(player, context)
    participants = all_participants(matches, context)
    {:reply,
     participants |> Map.values |> Enum.map(&Riot.name/1),
     %{state | matches: matches, participants: participants, context: context},
     {:continue, {:process_expired_matches}}}
  rescue
    error -> {:stop, error, state}
  end

  @impl true
  def handle_continue({:process_expired_matches}, state) do
    expired_matches = state |> latest_matches() |> Enum.unzip() |> elem(1) |> MapSet.new
    {:noreply, %{state | matches: MapSet.union(state.matches, expired_matches)}}
  end

  @impl true
  def handle_info(:minute, state) do
    new_minute = state.minute + 1
    IO.puts "Minute #{new_minute} (#{DateTime.utc_now()})"
    new_matches = state |> latest_matches() |> Enum.reject(fn {_, match} -> MapSet.member?(state.matches, match) end)
    Enum.each(
      new_matches,
      fn {puuid, match} -> IO.puts "Summoner #{Riot.name(state.participants[puuid])} completed match #{match}" end
    )

    matches = MapSet.union(state.matches, new_matches |> Enum.unzip() |> elem(1) |> MapSet.new)
    {:noreply, %{state | minute: new_minute, matches: matches}}
  end

  @impl true
  def handle_info(:hour, state) do
    System.halt(0)
    {:stop, "Finished", state}
  end

  def latest_matches(state) do
    state.participants
    |> Map.keys
    |> Enum.flat_map(&Riot.last_match(&1, state.context))
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
