defmodule Riot do
  @moduledoc "Wrapper around the Riot REST API"

  @regions %{
    "br1" => "americas",
    "na1" => "americas",
    "la1" => "americas",
    "la2" => "americas",

    "jp1" => "asia",
    "kr1" => "asia",

    "eun1" => "europe",
    "euw1" => "europe",
    "ru" => "europe",
    "tr1" => "europe",

    "oc1" => "sea",
    "ph2" => "sea",
    "th2" => "sea",
    "tw2" => "sea"
  }
  @player_by_name "/lol/summoner/v4/summoners/by-name/:name"
  @player_by_puuid "/lol/summoner/v4/summoners/by-puuid/:puuid"
  @matches_by_puuid "/lol/match/v5/matches/by-puuid/:puuid/ids"
  @get_match "/lol/match/v5/matches/:match_id"

  def continent(region), do: @regions[region] || "americas"

  defp req(region) do
    Req.new(base_url: "https://#{region}.api.riotgames.com")
  end

  @second 1_000
  @minute 60 * @second

  defp throttle(f, interval, frequency) do
    case Hammer.check_rate("riot_games", interval, frequency) do
      {:allow, _count} ->
        f.()
      {:deny, _limit} ->
        :timer.sleep(div(interval, frequency))
        throttle(f, interval, frequency)
    end
  end

  defp minute_throttle(f), do: throttle(f, 2 * @minute, 100)
  defp second_throttle(f), do: throttle(f, @second, 20)

  defp raw_get(url, path_params, params, context, opts) do
    shard = Map.get(opts, :shard, :continent)
    Req.get!(
      req(context[shard]),
      url: url,
      path_params: path_params,
      params: params,
      headers: [{"X-Riot-Token", Application.fetch_env!(:riot_summary, :riot_api_key)}],
      decode_json: [keys: :atoms]
    )
  end

  defp get(url, path_params, params, context, opts \\ %{}) do
    minute_throttle(fn -> second_throttle(fn -> raw_get(url, path_params, params, context, opts) end) end)
  end

  def player_by_name(name, context) do
    get(@player_by_name, [name: name], [], context, %{shard: :region})
  end

  def player_by_puuid(puuid, context) do
    get(@player_by_puuid, [puuid: puuid], [], context, %{shard: :region})
  end

  def matches_by_puuid(puuid, context, params \\ []) do
    get(@matches_by_puuid, [puuid: puuid], params, context)
  end

  def match(match, context) do
    get(@get_match, [match_id: match], [], context)
  end

  def last_match(puuid, context) do
    case matches_by_puuid(puuid, context, [count: 1]) do
      %Req.Response{status: 200, body: [match]} -> [{puuid, match}]
      _ -> []
    end
  end

  def name(info) do
    if info.name in [nil, ""] do
      "<#{info.puuid}>"
    else
      info.name
    end
  end
end
