# Leader

## Setup

`mix deps.get`

`mix ecto.create`

`mix ecto.migrate`

## Starting

Start K Nodes each with different name
	
	iex --sname node1 -S mix
	

See the logs what are the messages being sent and received in all the nodes

Close master Node (ctrl + C + C ) and see other node taking it over.
The closed node is deleted from DB too.

## Things Missing

Tests, CI, Release 