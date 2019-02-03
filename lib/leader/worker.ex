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

    state = %{name: to_string(Node.self()), is_master: false}

    NodeDetails.create(state)
    # Process.send_after(self(), :send_ping, ping_interval * 1000)
    IO.puts("New Node Connected so lets start the election process")
    send_msg(self(), :elect)
    
    state =
      state
      |> Map.put(:ping_interval, ping_interval)

    {:ok, state}
  end

  def handle_call({:ping, pid}, _from, state) do
    IO.puts("I received the ping ")
    IO.inspect(pid)
    send_msg(pid, :respond)
    {:reply, :ok, state}
  end

  def handle_call(msg, from, state) do
    IO.puts("I received the msg #{msg} from the #{from}")
    # send_msg(pid, :respond)
    {:reply, :ok, state}
  end

  def handle_info(:elect, state) do
    masternode = NodeDetails.get_master_node()
    
    IO.puts("masternode in elect is #{masternode}")
    
    case masternode do
      nil -> :ok
      _ -> NodeDetails.update(masternode, %{is_master: false})
    end
    
    elect()
    {:noreply, %{state | is_master: false}}
  end

  def handle_info(:respond, state) do
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
    case masternode do
      nil ->
        IO.puts("Master node not available")
      
      masternode_string ->
        masternode = String.to_atom(masternode_string)
        
        masterpid =
          {masternode, __MODULE__}
          |> :global.whereis_name()

        IO.inspect("masternode is #{masternode}")
        IO.inspect(masterpid)

        case masterpid do
          :undefined ->
            IO.puts("Master is Down because undefined")
            elect()
          ^masterpid when is_pid(masterpid) ->
            try do
              :ok = GenServer.call(masterpid, {:ping, self()}, ping_interval * 4 * 1000)
              Process.send_after(self(), :send_ping, ping_interval * 1000)
            catch
              :exit, value ->
                IO.puts("Master is Down #{value}")
                NodeDetails.update(masternode_string, %{is_master: false})
                elect()
            end
        end
    end

    {:noreply, state}
  end

  def handle_info({:ALIVE?, pid}, state) do
    IO.inspect("Received Alive")
    IO.inspect(pid)
    send_msg(pid, :FINETHANKS)
    case biggest?() do
      true ->
        nodes = NodeDetails.get_all_nodes()
        Enum.each(nodes, fn node -> 
          {node, __MODULE__}
          |> :global.whereis_name()
          |> send_msg({:IAMTHEKING, self()}) 
        end)
        
      false ->
        elect()
    end
    {:noreply, state}
  end

  def handle_info({:IAMTHEKING, pid}, state) when pid == self() do
    IO.inspect("I am the new Master")
    NodeDetails.update(to_string(Node.self()), %{is_master: true})
    {:noreply, %{state | is_master: true}}
  end

  def handle_info({:IAMTHEKING, pid}, %{ping_interval: ping_interval} = state) do
    IO.inspect("We have the new Master")
    NodeDetails.update(to_string(Node.self()), %{is_master: false})
    
    Process.send_after(self(), :send_ping, ping_interval * 1000)
    {:noreply, %{state | is_master: false}}
  end

  def elect() do
    ping_interval = Application.get_env(:leader, :ping_interval)

    nodes = 
      Node.self()
      |> to_string()
      |> NodeDetails.get_id()
      |> NodeDetails.get_nodes_by_greater_than_id()

    IO.inspect nodes

    Enum.each(nodes, fn node -> 
      nodepid =
        {node, __MODULE__}
        |> :global.whereis_name()

      IO.inspect nodepid 
      send_msg(nodepid, {:ALIVE?, self()})
    end)

    :timer.sleep(ping_interval * 1000)
    # check for flush_all
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, 0} ->
        nodes = NodeDetails.get_all_nodes()

        Enum.each(nodes, fn node ->
          nodepid =
            {node, __MODULE__}
            |> :global.whereis_name()

          send_msg(nodepid, {:IAMTHEKING, self()})
        end)
      any ->
        IO.inspect("Whats in the box")
        # clear_mailbox()
        :ok
    end

  end

  defp biggest?() do
    true
  end

  defp send_msg(:undefined, msg) do
    :ok
  end

  defp send_msg(pid, msg) do
    send(pid, msg)
  end
  
  # defp clear_mailbox() do
  #   receive do
  #     :FINETHANKS ->
  #       clear_mailbox()
  #     any ->
  #       IO.inspect(any)
  #     after
  #       2000 -> :ok
  #   end
  # end
end
