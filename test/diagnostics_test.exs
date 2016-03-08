defmodule DiagnosticsTest do
  use ExUnit.Case
  alias Diagnostics
  alias Test.Process

  test "Largest process" do
    {:ok, big_process} = Process.start_link Enum.to_list(1..1000)
    {:ok, small_process} = Process.start_link :nil

    [%{pid: largest_process}, %{pid: next_largest_process}] = Diagnostics.processes_by_size("Test", 2)
    assert big_process == largest_process
    assert small_process == next_largest_process

    [%{pid: largest_process}, %{pid: next_largest_process}] = Diagnostics.processes_by_size("Test")
    assert big_process == largest_process
    assert small_process == next_largest_process

    all_pids = Diagnostics.processes_by_size(1000)
               |> Enum.map(fn %{pid: pid} -> pid end)
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
    {:ok, process} = Process.start_link :nil
    assert "Elixir.#{inspect Test.Process}" == Diagnostics.module_name process
  end

  test "Size" do
    {:ok, small_process} = Process.start_link :nil
    {:ok, big_process} = Process.start_link Enum.to_list(1..1000)
    small_process_size = Diagnostics.size small_process
    big_process_size = Diagnostics.size big_process

    assert small_process_size < big_process_size
  end

end

defmodule Test.Process do
  def start_link(state) do
    Agent.start_link(fn -> state end)
  end
end
