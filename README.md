# Leader

`mix deps.get`
`mix ecto.create`
`mix ecto.migrate`

Start the Nodes Each with different name
	Terminal One -> 	`iex --sname node1 -S mix`
	Terminal Two -> 	`iex --sname node2 -S mix`
	Terminal Three -> `iex --sname node3 -S mix`
  And So On ....

See the logs what are the messages being sent and received in all the nodes

Close master Node (ctrl + C + C ) and see other node taking it over.
The closed node is deleted from DB too.
