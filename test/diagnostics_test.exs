defmodule DiagnosticsTest do
  use ExUnit.Case
  alias Diagnostics
  alias Test.Process

  test "Processes by size" do
    {:ok, big_process} = Process.start_link large_state
    {:ok, small_process} = Process.start_link small_state

    [%{pid: largest_process}, %{pid: next_largest_process}] = Diagnostics.processes_by_size("Test", 2)
    assert big_process == largest_process
    assert small_process == next_largest_process

    [%{pid: largest_process}, %{pid: next_largest_process}] = Diagnostics.processes_by_size("Test")
    assert big_process == largest_process
    assert small_process == next_largest_process

    all_pids = Diagnostics.processes_by_size |> Enum.map(fn %{pid: pid} -> pid end)
    assert big_process in all_pids
    assert small_process in all_pids

    all_pids = Diagnostics.processes_by_size(1000) |> Enum.map(fn %{pid: pid} -> pid end)
    assert big_process in all_pids
    assert small_process in all_pids
  end

  test "Processes by module" do
    process_count = 10000
    1..process_count |> Enum.each(fn _ -> Process.start_link nil end)
    [{module_name, count, _}| _] = Diagnostics.processes_by_module
    assert "#{Process}" == module_name
    assert process_count == count
  end

  test "Processes by large binary refs" do
    binary1 = 1..1000 |> Enum.reduce(<<>>, fn(x, acc) -> acc <> to_string(x) end) 
    binary2 = 1001..2000 |> Enum.reduce(<<>>, fn(x, acc) -> acc <> to_string(x) end) 
    binary1_size = byte_size binary1
    both_binary_size = byte_size(binary2) + binary1_size

    {:ok, pid} = Process.start_link [binary1, binary2]
    assert [%{info: %{duplicates: 0, unique: 2, total: 2, size: ^both_binary_size}}] = Diagnostics.processes_by_large_binary_size("Test", 2)
    Agent.stop pid 

    {:ok, pid} = Process.start_link [binary1, binary1]
    assert [%{info: %{duplicates: 1, unique: 1, total: 2, size: ^binary1_size}}] = Diagnostics.processes_by_large_binary_size("Test", 1)
    Agent.stop pid 
  end

  test "Module name" do
    {:ok, process} = Process.start_link small_state
    assert "Elixir.#{inspect Test.Process}" == Diagnostics.module_name process
  end

  test "Size" do
    {:ok, small_process} = Process.start_link small_state
    {:ok, big_process} = Process.start_link large_state

    small_process_size = Diagnostics.size small_process
    big_process_size = Diagnostics.size big_process

    assert small_process_size < big_process_size
  end

  test "State" do
    {:ok, process} = Process.start_link large_state
    expected_state_size = Diagnostics.words_to_mb(:erts_debug.flat_size(large_state))

    assert Diagnostics.state_size(process) == expected_state_size
    assert Diagnostics.state(process) == %{state: large_state, size: expected_state_size}
  end

  def large_state, do: Enum.to_list(1..1000)
  def small_state, do: :nil
end

defmodule Test.Process do
  def start_link(state) do
    Agent.start_link(fn -> state end)
  end
end
