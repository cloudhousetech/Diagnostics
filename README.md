# Diagnostics

A collection of diagnostic bits and pieces for Elixir. 

Examples (these are called from a remote node):

Get module name from pid
```elixir
:rpc.call(@node, Diagnostics, :module_name, [pid])
```

Get the size of a process
```elixir
:rpc.call(@node, Diagnostics, :size, [pid])
```

List the processes in the system using the most memory (heap and stack) by module name and the count of them running on the node
```elixir
:rpc.call(@node, Diagnostics, :processes_by_module, [])
```

List all processes created by Module MyModule in namespace MyApp ordered by size
```elixir
:rpc.call(@node, Diagnostics, :processes_by_size, ["MyApp.MyModule"])
```

List top 10 processes created by Module MyModule in namespace MyApp ordered by size
```elixir
:rpc.call(@node, Diagnostics, :processes_by_size, ["MyApp.MyModule", 10])
```

List all processes ordered by size
```elixir
:rpc.call(@node, Diagnostics, :processes_by_size, [])
```

List all processes created by Module MyModule in namespace MyApp ordered by proc bin size
```elixir
:rpc.call(@node, Diagnostics, :processes_by_large_binary_size, ["MyApp.MyModule"])
```

List top 10 processes created by Module MyModule in namespace MyApp ordered by proc bin size
```elixir
:rpc.call(@node, Diagnostics, :processes_by_large_binary_size, ["MyApp.MyModule", 10])
```

List all processes ordered by proc bin size
```elixir
:rpc.call(@node, Diagnostics, :processes_by_large_binary_size, [])
```


