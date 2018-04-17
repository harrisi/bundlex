defmodule Bundlex.Makefile do
  @moduledoc """
  Structure encapsulating makefile generator.
  """

  @script_name unix: "bundlex.sh", windows: "bundlex.bat"
  @script_prefix unix: "#!/bin/sh\n", windows: ""

  @type t :: %__MODULE__{
          commands: command_t
        }

  @type command_t :: String.t()

  defstruct commands: []

  @doc """
  Creates new makefile.
  """
  @spec new([command_t]) :: t
  def new(commands \\ []) do
    %__MODULE__{commands: commands}
  end

  @spec run!(t, Bundlex.Platform.platform_name_t()) :: :ok
  def run!(%__MODULE__{commands: commands}, _platform) do
    commands
    |> Enum.each(fn cmd ->
      ret = cmd |> Mix.shell().cmd

      if ret != 0 do
        Mix.raise("Command #{cmd} returned non-zero code: #{ret}")
      end
    end)

    :ok
  end

  @spec store!(t, Bundlex.Platform.platform_name_t()) :: {:ok, String.t()}
  def store!(%__MODULE__{commands: commands}, platform) do
    family = platform |> family!()
    script_name = @script_name[family]
    script_prefix = @script_prefix[family]
    script = script_prefix <> (commands |> Enum.join("\n"))
    File.write!(script_name, script)
    if family == :unix, do: File.chmod!(script_name, 0o755)
    {:ok, script_name}
  end

  defp family!(:windows32), do: :windows
  defp family!(:windows64), do: :windows
  defp family!(:macosx), do: :unix
  defp family!(:linux), do: :unix
end
