defmodule RiotApp do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([{RiotSummary, []}], strategy: :one_for_one)
  end
end
