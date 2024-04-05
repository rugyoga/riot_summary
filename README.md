# RiotSummary

Basic implementation of Blitz take home

Usage:

```bash
RIOT_API_KEY=<...> mix summoners <player> <region>
```

# Gory details

The Riot API requires an API key.
We don't want that stored in the repo so we access from the shell environment
via System.

```elixir
:timer.send_interval(60_000, :minute)
```

sends a :minute info message every 60 seconds to the GenServer.
reference: https://stackoverflow.com/questions/46869458/running-a-task-on-a-timer

The Riot API has two rate limits: 10/second and 200/minute
We enforce this using Hammer.