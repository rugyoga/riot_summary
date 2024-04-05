defmodule Riot do
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

  def req(region) do
    Req.new(base_url: "https://#{region}.api.riotgames.com")
  end

  def rate_limit(f) do
    case Hammer.check_rate("riot_games", 1_000, 20) do
      {:allow, _count} ->
        case Hammer.check_rate("riot_games", 120_000, 100) do
          {:allow, _count} ->
            f.()
          {:deny, _limit} ->
            :timer.sleep(1200)
            rate_limit(f)
        end
      {:deny, _limit} ->
        :timer.sleep(50)
        rate_limit(f)
    end
  end

  def get(url, path_params, params, context, opts \\ %{}) do
    shard = Map.get(opts, :shard, :continent)
    rate_limit(
      fn ->
        Req.get!(
          req(context[shard]),
          url: url,
          path_params: path_params,
          params: params,
          headers: [{"X-Riot-Token", Application.fetch_env!(:riot_summary, :riot_api_key)}],
          decode_json: [keys: :atoms]
        )
      end
    )
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
end
