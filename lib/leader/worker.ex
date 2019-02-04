defmodule Leader.Worker do
  @moduledoc false
  use GenServer
  require Logger
  alias Leader.IO.NodeDetails
  alias Leader.Utils

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: {:global, {Node.self(), __MODULE__}})
  end

  def init([]) do
    nodes = NodeDetails.get_all_nodes()
    Enum.each(nodes, fn node -> Node.connect(node) end)
    ping_interval = Application.get_env(:leader, :ping_interval)

    state = %{name: to_string(Node.self()), is_master: false}

    NodeDetails.create(state)
    IO.puts("New Node Connected so lets start the election process")
    Utils.send_msg(self(), :elect)

    state =
      state
      |> Map.put(:ping_interval, ping_interval)

    {:ok, state}
  end

  def handle_call({:ping, pid}, _from, state) do
    IO.puts("I received the ping ")
    Utils.send_msg(pid, :respond)
    {:reply, :ok, state}
  end

  def handle_info(:elect, state) do
    masternodes = NodeDetails.get_master_node()

    IO.puts("Election Process starts")

    case masternodes do
      nil ->
        :ok

      _ ->
        Enum.each(masternodes, fn masternode ->
          NodeDetails.update(masternode, %{is_master: false})
        end)
    end

    elect()
    {:noreply, %{state | is_master: false}}
  end

  def handle_info(:respond, state) do
    IO.puts("Received Response from the master")
    {:noreply, state}
  end

  def handle_info(:send_ping, %{is_master: true} = state) do
    IO.inspect("I am the master so I will not send ping")
    {:noreply, state}
  end

  def handle_info(:send_ping, %{ping_interval: ping_interval} = state) do
    IO.puts("sending ping to master")

    masternode =
      NodeDetails.get_master_node()
      |> List.first()

    case masternode do
      nil ->
        IO.puts("Master not available")

      masternode_string ->
        masternode = String.to_atom(masternode_string)

        masterpid =
          {masternode, __MODULE__}
          |> :global.whereis_name()

        IO.inspect("masternode is #{masternode}")

        case masterpid do
          :undefined ->
            IO.puts("Master is Down")
            send(self(), :elect)

          ^masterpid when is_pid(masterpid) ->
            try do
              :ok = GenServer.call(masterpid, {:ping, self()}, ping_interval * 4 * 1000)
              Process.send_after(self(), :send_ping, ping_interval * 1000)
            catch
              :exit, value ->
                IO.puts("Master is Down #{value}")
                NodeDetails.update(masternode_string, %{is_master: false})
                send(self(), :elect)
            end
        end
    end

    {:noreply, state}
  end

  def handle_info({:ALIVE?, pid}, state) do
    IO.inspect("Received ALIVE?")
    Utils.send_msg(pid, :FINETHANKS)

    case Utils.biggest?() do
      true ->
        nodes = NodeDetails.get_all_nodes()

        Enum.each(nodes, fn node ->
          {node, __MODULE__}
          |> :global.whereis_name()
          |> Utils.send_msg({:IAMTHEKING, self()})
        end)

      false ->
        send(self(), :elect)
    end

    {:noreply, state}
  end

  def handle_info(:FINETHANKS, state) do
    IO.inspect("Received FINETHANKS")
    {:noreply, state}
  end

  def handle_info({:IAMTHEKING, pid}, state) when pid == self() do
    IO.inspect("I Am New Master")
    NodeDetails.update(to_string(Node.self()), %{is_master: true})
    Utils.remove_inactive_nodes()
    {:noreply, %{state | is_master: true}}
  end

  def handle_info({:IAMTHEKING, pid}, %{ping_interval: ping_interval} = state) do
    IO.inspect("We have a new master")
    IO.inspect(pid)

    NodeDetails.update(to_string(Node.self()), %{is_master: false})
    Process.send_after(self(), :send_ping, ping_interval * 1000)
    {:noreply, %{state | is_master: false}}
  end

  def elect() do
    ping_interval = Application.get_env(:leader, :ping_interval)

    nodes = Utils.get_nodes_having_id_greater_than_me()

    Enum.each(nodes, fn node ->
      nodepid =
        {node, __MODULE__}
        |> :global.whereis_name()

      Utils.send_msg(nodepid, {:ALIVE?, self()})
    end)

    receive do
      :FINETHANKS ->
        IO.inspect("Received FINETHANKS")
        :ok
    after
      ping_interval * 1000 ->
        nodes = NodeDetails.get_all_nodes()

        Enum.each(nodes, fn node ->
          nodepid =
            {node, __MODULE__}
            |> :global.whereis_name()

          Utils.send_msg(nodepid, {:IAMTHEKING, self()})
        end)
    end
  end
end
