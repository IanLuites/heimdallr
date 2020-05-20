defmodule Heimdallr.Watcher do
  @moduledoc false
  use GenServer

  @stagger 100

  def start_link(dirs) do
    GenServer.start_link(__MODULE__, dirs, name: __MODULE__)
  end

  def init(dirs) do
    {:ok, pid} = FileSystem.start_link(dirs: dirs)
    FileSystem.subscribe(pid)
    {:ok, %{fs: pid, changed: [], timer: nil}}
  end

  def handle_info(:process, state = %{changed: changes}) do
    spawn(fn -> Heimdallr.reload(changes) end)

    {:noreply, %{state | changed: [], timer: nil}}
  end

  def handle_info({:file_event, fs, {f, events}}, state = %{fs: fs, changed: c, timer: t}) do
    file = "./" <> Path.relative_to_cwd(f)
    {changed?, changes} = new_changes(file, events, {false, c})

    if changed? do
      t && Process.cancel_timer(t, async: false, info: false)
      timer = Process.send_after(self(), :process, @stagger)

      {:noreply, %{fs: fs, changed: changes, timer: timer}}
    else
      {:noreply, state}
    end
  end

  defp new_changes(file, events, {changed?, acc}) do
    if Enum.any?(events, &(&1 in [:created, :modified, :deleted])) and file not in acc do
      {true, [file | acc]}
    else
      {changed?, acc}
    end
  end

  def terminate(reason, %{fs: fs}) do
    GenServer.stop(fs, reason)
    :ok
  end

  # watch = dirs |> Enum.map(&inspect/1) |> Enum.join(" ")
  # cmd = ~s|inotifywait -r -m -e move,modify,create,delete #{watch}|
  # port = Port.open({:spawn, cmd}, [:binary, :use_stdio, :stderr_to_stdout, :exit_status])

  # {:ok, %{port: port, changed: [], timer: nil}}
  # def handle_info({port, {:data, change}}, state = %{port: port, changed: c, timer: t}) do
  #   {changed?, changes} =
  #     change |> String.split(~r/\r?\n/, trim: true) |> Enum.reduce({false, c}, &new_changes/2)

  #   if changed? do
  #     t && Process.cancel_timer(t, async: false, info: false)
  #     timer = Process.send_after(self(), :process, @stagger)

  #     {:noreply, %{port: port, changed: changes, timer: timer}}
  #   else
  #     {:noreply, state}
  #   end
  # end

  # defp new_changes(line, {changed?, acc}) do
  #   {file, type} =
  #     case line |> String.trim() |> String.split(" ") do
  #       [dir, change] -> {dir, change}
  #       [dir, change, file] -> {to_string(Path.join(dir, file)), change}
  #       _ -> {nil, nil}
  #     end

  #   if type != nil and type in ~W(CREATE MODIFY DELETE) and file not in acc do
  #     {true, [file | acc]}
  #   else
  #     {changed?, acc}
  #   end
  # end
end
