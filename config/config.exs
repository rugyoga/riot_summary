import Config

config :hammer, backend: {Hammer.Backend.ETS, [expiry_ms: 1_000 * 60 * 4, cleanup_interval_ms: 1_000 * 60 * 60]}
