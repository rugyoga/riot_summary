# RiotSummary

Basic implementation of Blitz take home

Usage:

```bash
RIOT_API_KEY=<...> mix summoners <player> <region>
```

# Gory details

The Riot API requires an API key.
We don't want that stored in the repo so we access it from the shell environment
via System.get_env("RIOT_API_KEY") in the config/runtime.exs
Not config/config.exs because that grabs the value at COMPILE time.
Ther most elegant way to supply this in the HTTP request as a header: `X-Riot-Token`.

We want to publish an update to this conssole every 60 seconds for an hour.
We accomplish this by:

```elixir
:timer.send_interval(60_000, :minute)
```

in the GenServer `init`` function..
reference: https://stackoverflow.com/questions/46869458/running-a-task-on-a-timer

The Riot API has two rate limits: 10/second and 200/minute
We enforce this using Hammer.

To find a player to test it on, I hopped on twitch.tv and looked for an active LOL streamer.
Found `imaqtpie` on the `na1` server.

Riot seems to have two different notions of server:
one is regional and the other is continental.

Some folk seem to have blank names so substituting `<puuid>` instead.
