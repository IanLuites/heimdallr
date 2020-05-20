defmodule Heimdallr do
  @moduledoc """
  Documentation for `Heimdallr`.
  """

  alias Mix.Tasks.Compile.Elixir, as: ElixirCompiler

  @compile_opts ~W(--docs --ignore-module-conflict)

  def reload(files) do
    code = Enum.filter(files, &String.starts_with?(&1, "./lib/"))
    test = Enum.filter(files, &String.starts_with?(&1, "./test/"))

    case ElixirCompiler.run(@compile_opts) do
      {:noop, _} -> :ok
      {:ok, diagnostics} -> process_code_reload(code, diagnostics)
      {:error, _} -> :ok
    end

    # After re-index, see what depends
    process_test_change(test ++ Enum.flat_map(code, &Heimdallr.Indexer.tests/1))
  end

  defp process_code_reload(files, _diagnostics) do
    if files != [] and Application.get_env(:heimdallr, :run_checks, true) do
      Credo.CLI.main(["--mute-exit-status", "--strict", "list" | files])
    end

    Enum.each(files, &Heimdallr.Indexer.i/1)

    :ok
  end

  defp process_test_change(tests) do
    if tests != [] do
      IO.puts(elem(execute("mix", ["test", "--color" | tests]), 0))
    end

    :ok
  end

  @spec execute(String.t(), [String.t()]) :: {String.t(), integer}
  defp execute(command, options) do
    case :os.type() do
      {:unix, :darwin} ->
        commands = ["-q", "/dev/null", command] ++ options

        System.cmd("script", commands)

      {:unix, _} ->
        System.cmd(command, options, stderr_to_stdout: true)
    end
  end
end
