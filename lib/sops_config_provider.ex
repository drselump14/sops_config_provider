defmodule SopsConfigProvider do
  @behaviour Config.Provider

  alias SopsConfigProvider.Sops
  alias SopsConfigProvider.State
  alias SopsConfigProvider.Utils

  defmodule InitStateError do
    defexception message: ~s"""
                    Please set appropriate options maps as second parameter on the release.
                    Example:
                      release: [
                         my_app: [
                           config_providers: [
                             {SopsConfigProvider, %{app_name: :my_app, secret_file_path: "/path", sops_binary_path: "/usr/local/bin/sops"}}
                           ]
                         ]
                      ]
                 """
  end

  @impl true
  @spec init(State.t() | map() | term()) :: State.t()
  def init(%State{} = state), do: state
  def init(state) when is_map(state), do: state |> State.new!()

  def init(_),
    do: raise(InitStateError)

  @impl true
  def load(config, %State{} = state) do
    # Need a right path for the secret file on release package

    sops_config =
      state
      |> Sops.check_sops_availability!()
      |> Utils.resolve_secret_file_location!()
      |> Utils.get_file_type()
      |> Sops.decrypt!()
      |> Utils.convert_to_map!()
      |> Map.to_list()

    Config.Reader.merge(
      config,
      sops: sops_config
    )
  end
end
