defmodule SopsConfigProvider.Utils do
  @moduledoc """
  Utils to process sops encrypted file
  """

  alias SopsConfigProvider.State

  defmodule SecretFileNotFoundError do
    defexception [:message]

    def exception(file_path) do
      %__MODULE__{message: "[ERROR] File not found. File file_path: #{file_path}"}
    end
  end

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

  defmodule YAMLReadError do
    defexception [:message]

    def exception(detail) do
      %__MODULE__{message: "[ERROR] can't read the YAML File. Detail: #{detail}"}
    end
  end

  defmodule JSONReadError do
    defexception [:message]

    def exception(detail) do
      %__MODULE__{message: "[ERROR] can't read the JSON File. Detail: #{detail}"}
    end
  end

  @spec resolve_secret_file_location!(State.t()) :: State.t()
  def resolve_secret_file_location!(
        %State{app_name: app_name, secret_file_path: secret_file_path} = state
      ) do
    file_path =
      app_name
      |> Application.app_dir(secret_file_path)

    unless file_path |> File.exists?() do
      raise SecretFileNotFoundError, file_path
    end

    state |> Map.put(:secret_file_path, file_path) |> State.ensure_type!()
  end

  @spec check_sops_availability!(State.t()) :: State.t()
  def check_sops_availability!(%State{sops_binary_path: sops_binary_path} = state) do
    case System.cmd(sops_binary_path, ["--version"]) do
      {_output, 0} -> state
      _ -> raise SopsNotInstalledError, sops_binary_path
    end
  end

  @spec get_file_type(State.t()) :: State.t()
  def get_file_type(%State{secret_file_path: secret_file_path} = state) do
    file_type =
      case secret_file_path |> Path.extname() do
        ".json" -> :json
        ".yaml" -> :yaml
        ".yml" -> :yaml
      end

    state |> Map.put(:file_type, file_type) |> State.ensure_type!()
  end

  @spec decrypt!(State.t()) :: State.t()
  def decrypt!(
        %State{sops_binary_path: sops_binary_path, secret_file_path: secret_file_path} = state
      ) do
    case System.cmd(sops_binary_path, ["-d", secret_file_path]) do
      {output, 0} -> state |> Map.put(:sops_content, output) |> State.ensure_type!()
      {error, _} -> raise SopsDecryptError, error
    end
  end

  @spec convert_to_map!(State.t()) :: map()
  def convert_to_map!(%State{sops_content: sops_content, file_type: :yaml}) do
    case YamlElixir.read_from_string(sops_content, atoms: true) do
      {:ok, content} -> content |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)
      {:error, detail} -> raise YAMLReadError, detail
    end
  end

  def convert_to_map!(%State{sops_content: sops_content, file_type: :json}) do
    case sops_content |> Jason.decode(keys: :atoms!) do
      {:ok, content} -> content
      {:error, detail} -> raise JSONReadError, detail
    end
  end
end
