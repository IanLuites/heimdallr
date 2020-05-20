defmodule Heimdallr.Indexer do
  @moduledoc false
  use GenServer

  def tests(file) do
    GenServer.call(__MODULE__, {:tests, file})
  end

  def i(file), do: GenServer.call(__MODULE__, {:index, file})

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_) do
    base = %{code: %{}, test: %{}}
    files = Path.wildcard("./lib/**/*.ex") ++ Path.wildcard("./test/**/*.exs")
    files = Enum.map(files, &"./#{&1}")
    {:ok, Enum.reduce(files, base, &index/2)}
  end

  def handle_call({:tests, file}, _, state = %{code: c, test: t}) do
    modules = c[file] || []

    tests =
      t
      |> Enum.filter(fn {_, v} -> Enum.any?(modules, &(&1 in v)) end)
      |> Enum.map(&elem(&1, 0))

    {:reply, tests, state}
  end

  def handle_call({:index, file}, _, state) do
    {:reply, :ok, index(file, state)}
  end

  defp index(file, state) do
    if String.starts_with?(file, "./test/"),
      do: index_test(file, state),
      else: index_code(file, state)
  end

  defp index_code(file, state = %{code: c}) do
    case File.read(file) do
      {:ok, data} ->
        mods =
          ~r/defmodule ([^\ ]+) do/
          |> Regex.scan(data)
          |> Enum.map(fn [_, b] -> b end)

        %{state | code: Map.put(c, file, mods)}

      _ ->
        %{state | code: Map.delete(c, file)}
    end
  end

  defp index_test(file, state = %{test: c}) do
    case File.read(file) do
      {:ok, data} ->
        mods =
          ~r/(doctest|import|alias) ([^\ \n]+)/
          |> Regex.scan(data)
          |> Enum.map(fn [_, _, b] -> b end)
          |> Enum.uniq()

        %{state | test: Map.put(c, file, mods)}

      _ ->
        %{state | test: Map.delete(c, file)}
    end
  end
end
