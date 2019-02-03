defmodule Leader.Worker do
  @moduledoc false
  use GenServer
  require Logger
  alias Leader.IO.NodeDetails

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: {:global, {Node.self(), __MODULE__}})
  end

  def init([]) do
    nodes = NodeDetails.get_all_nodes()
    Enum.each(nodes, fn node -> Node.connect(node) end)
    ping_interval = Application.get_env(:leader, :ping_interval)

    state =
      case nodes do
        [] ->
          %{name: to_string(Node.self()), is_master: true}

        _ ->
          %{name: to_string(Node.self()), is_master: false}
      end

    NodeDetails.create(state)
    Process.send_after(self(), :send_ping, ping_interval * 1000)

    state =
      state
      |> Map.put(:ping_interval, ping_interval)

    {:ok, state}
  end

  def handle_call({:ping, pid}, _from, %{ping_interval: ping_interval} = state) do
    IO.puts("I received the ping from the slaves")
    send(pid, :respond)
    {:reply, :ok, state}
  end

  def handle_info(:respond, %{ping_interval: ping_interval} = state) do
    IO.puts("I received the response from the master")

    {:noreply, state}
  end

  def handle_info(:send_ping, %{is_master: true} = state) do
    IO.inspect("I am the master so I will not send ping")
    {:noreply, state}
  end

  def handle_info(:send_ping, %{ping_interval: ping_interval} = state) do
    IO.puts("sending ping to master")
    masternode = NodeDetails.get_master_node()

    masterpid =
      {masternode, __MODULE__}
      |> :global.whereis_name()

    case masterpid do
      ^masterpid when is_pid(masterpid) ->
        try do
          :ok = GenServer.call(masterpid, {:ping, self()}, ping_interval * 4 * 1000)
          Process.send_after(self(), :send_ping, ping_interval * 1000)
        catch
          :exit, value ->
            IO.puts("Master is Down")
        end

      :undefined ->
        IO.puts("Master is Down")
    end

    {:noreply, state}
  end
end
