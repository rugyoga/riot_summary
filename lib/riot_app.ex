defmodule RiotApp do
  @moduledoc "Riot App responsible for creating the supervision tree."

  use Application

  def start(_type, _args) do
    Supervisor.start_link([{RiotSummary, []}], strategy: :one_for_one)
  end
end
