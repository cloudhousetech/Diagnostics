# Diagnostics

A collection of diagnostic bits and pieces for Elixir


Examples:

List the processes in the system using the most memory (heap and stack) by module name and the count of them running on the node
```elixir
IO.inspect :rpc.call(@node_name, Diagnostics, :processes_by_module, [])
```
