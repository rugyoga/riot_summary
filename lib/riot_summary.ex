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
    {:ok, %{minute: 0}}
  end

  @impl true
  def handle_call({:participants, player, region}, _from, state) do
    context = %{
      api_key: Application.fetch_env!(:riot_summary, :riot_api_key),
      region: region,
      continent: Riot.continent(region)
    }
    matches = recent(player, context)
    participants = all_participants(matches, context)
    {:reply, matches, %{state | matches: matches, participants: participants, context: context}}
  rescue
    error -> {:stop, error, state}
  end

  @impl true
  def handle_info(:minute, %{minute: minute, matches: matches} = state) do
    new_state = %{state | minute: minute+1, matches: MapSet.union(matches, new_matches(state))}
    if new_state.minute == 60 do
      {:stop, "Mission completed", new_state}
    else
      IO.puts "Minute #{new_state.minute}}\n"
      {:ok, new_state}
    end
  end

  def new_matches(%{context: context, matches: matches, participants: participants}) do
    participants
    |> Enum.reduce(
      [],
      fn {puuid, info}, new_matches ->
        case Riot.matches_by_puuid(puuid, context, [count: 1]) do
          %Req.Response{status: 200, body: [match]} ->
            if MapSet.member?(matches, match) do
              new_matches
            else
              IO.puts "Summoner #{info.name} completed match #{match}\n"
              MapSet.put(new_matches, match)
            end
          _ -> new_matches
        end
      end
    )
  end

  def recent(name, context) do
    name
    |> Riot.player_by_name(context)
    |> then(& &1.body.puuid)
    |> Riot.matches_by_puuid(context, [count: 5])
  end

  def all_participants(matches, context) do
    matches
    |> Enum.flat_map(fn match -> Riot.match(match, context).body.metadata.participants end)
    |> Enum.uniq()
    |> Enum.map(fn p -> {p, Riot.player_by_puuid(p, context).body} end)
    |> Map.new
  end
end
