defmodule SopsConfigProvider.Sops do
  @moduledoc """
  Utils to process sops encrypted file
  """

  alias SopsConfigProvider.SopsBehavior
  alias SopsConfigProvider.State

  @behaviour SopsBehavior

  defmodule SopsNotInstalledError do
    defexception [:message]

    def exception(sops_binary_path) do
      %__MODULE__{message: "[ERROR] Sops not found/installed in #{sops_binary_path}"}
    end
  end

  defmodule SopsDecryptError do
    defexception [:message]

    def exception(detail) do
      %__MODULE__{message: "[ERROR] SOPS is unable to decrypt the file. Detail: #{detail}"}
    end
  end

  @impl SopsBehavior
  @spec check_sops_availability!(State.t()) :: State.t()
  def check_sops_availability!(%State{sops_binary_path: sops_binary_path} = state) do
    case System.cmd(sops_binary_path, ["--version"]) do
      {_output, 0} -> state
      _ -> raise SopsNotInstalledError, sops_binary_path
    end
  end

  @impl SopsBehavior
  @spec decrypt!(State.t()) :: State.t()
  def decrypt!(
        %State{
          sops_binary_path: sops_binary_path,
          secret_file_path: secret_file_path,
          execution_dir: execution_dir,
          env_variables: env_variables
        } = state
      ) do
    case System.cmd(sops_binary_path, ["-d", secret_file_path],
           cd: execution_dir,
           env: env_variables
         ) do
      {output, 0} ->
        state
        |> Map.put(:sops_content, output)
        |> State.ensure_type!()

      {error, _} ->
        raise SopsDecryptError, error
    end
  end
end
