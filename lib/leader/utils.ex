defmodule Leader.Utils do
  alias Leader.IO.NodeDetails

  def biggest?() do
    get_nodes_having_id_greater_than_me()
    |> biggest?()
  end

  def biggest?([]) do
    true
  end

  def biggest?(_nodes_greater_than_me) do
    false
  end

  def get_nodes_having_id_greater_than_me() do
    Node.self()
    |> to_string()
    |> NodeDetails.get_id()
    |> NodeDetails.get_nodes_by_greater_than_id()
  end

  def send_msg(:undefined, _msg) do
    :ok
  end

  def send_msg(pid, msg) do
    send(pid, msg)
  end

  def remove_inactive_nodes() do
    all_nodes = NodeDetails.get_all_nodes()
    active_nodes = Node.list() ++ [Node.self()]

    (all_nodes -- active_nodes)
    |> Enum.map(fn inactive_node -> to_string(inactive_node) end)
    |> NodeDetails.delete_all()
  end
end
