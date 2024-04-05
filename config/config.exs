import Config

config :hammer, backend: {Hammer.Backend.ETS, [expiry_ms: 1_000 * 60 * 4, cleanup_interval_ms: 1_000 * 60 * 60]}

config :riot_summary, riot_api_key: System.get_env("RIOT_API_KEY")
