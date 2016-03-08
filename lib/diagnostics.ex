defmodule Diagnostics do
  def processes_by_size(text, count), do: processes_by_size(text) |> Enum.take(count)
  def processes_by_size(count) when is_number(count), do: processes_by_size("") |> Enum.take(count)
  def processes_by_size(text) do
    process_stream(text, modules_by_size)
    |> Enum.sort_by(fn %{info: {_, size}} -> -size end)
  end

  def processes_by_large_binary_size(text, count), do: processes_by_large_binary_size(text) |> Enum.take(count)
  def processes_by_large_binary_size(count) when is_number(count), do: processes_by_large_binary_size("") |> Enum.take(count)
  def processes_by_large_binary_size(text) do
    process_stream(text, modules_by_binary_refs)
    |> Enum.sort_by(fn %{info: %{size: total}} -> -total end)
  end

  def processes_by_module do
    process_stream(modules_by_size)
    |> Stream.map(fn %{module: module, info: {_, size}} -> {module, size} end)
    |> Enum.group_by(fn {module, _} -> module end)
    |> Map.to_list
    |> Stream.map(fn {module, list} -> {module, list |> Enum.count, list |> Enum.map(fn {_, size} -> size end) |> Enum.sum} end) 
    |> Enum.sort_by(fn {_, _, size} -> -size end)
  end

  def module_name(pid), do: module(:erlang.process_info(pid))

  def size(pid) do
    do_size(:erlang.process_info(pid))
  end

  def state_size(pid) do
    {:status, _, _, [_, _, _, _, state]} = :sys.get_status pid
    words_to_mb(:erts_debug.flat_size(state_data(state)))
  end

  defp state_data([{:data, [{'State', state}]}| tail]) do
    state
  end

  defp state_data([head|tail]) do
    state_data tail
  end

  defp state_data([]) do
  end

  defp process_stream("", fun), do: process_stream(fun)
  defp process_stream(text, fun), do: process_stream(fun) |> Stream.filter(fn %{module: module} -> module |> String.contains?(text) end)
  defp process_stream(fun) do
    :erlang.processes
    |> fun.()
  end

  defp modules_by_size do
    fn modules ->
      modules
      |> Stream.map(fn process -> {process, :erlang.process_info(process)} end)
      |> Stream.map(fn {process, info} -> %{module: module(info), pid: process, info: {info, do_size(info)}} end)
    end
  end

  defp modules_by_binary_refs do
    fn modules ->
      modules 
      |> Stream.map(fn process -> 
        case :erlang.process_info(process, :binary) do
          {:binary, bin_info} -> {process, bin_info} 
          _ -> :no_proc
        end
      end)
      |> Stream.filter(fn x -> x != :no_proc end)
      |> Stream.map(fn {process, bin_info} -> binary_refs_count({process, bin_info}) end)
    end
  end

  defp binary_refs_count({process, bin_info}) do
    unique_refs = Enum.dedup_by(bin_info, fn {ref, _, _} -> ref end)
    total_do_size = Enum.map(unique_refs, fn({_, do_size, _}) -> do_size end) |> Enum.sum

    count = Enum.count bin_info
    unique_count = Enum.count unique_refs

    %{module: module(:erlang.process_info(process)), 
      pid: process, 
      info: %{total: count, unique: unique_count, size: total_do_size, duplicates: (count - unique_count)}}
  end

  defp do_size(:undefined), do: 0
  defp do_size(info), do: words_to_mb(info[:total_heap_size])

  defp module(:undefined), do: "No longer exists"
  defp module(%{"$initial_call": {module, _, _}}), do: module |> to_string
  defp module(%{dictionary: dictionary}), do: module dictionary
  defp module(info) when is_list(info), do: module info |> Map.new
  defp module(_), do: "Unknown"

  def words_to_mb(words) do
    (words * :erlang.system_info(:wordsize)) |> in_mb
  end

  def in_mb(bytes) do
    Float.round(bytes/(1024*1024), 4)
  end
end
