defmodule SopsConfigProvider do
  @behaviour Config.Provider

  alias SopsConfigProvider.State
  alias SopsConfigProvider.Utils

  require Logger

  defmodule InitStateError do
    defexception message: ~s"""
                    Please set %SopsConfigProvider.State{} as second parameter on the release.
                    Example:
                      release: [
                         my_app: [
                           config_providers: [
                             {SopsConfigProvider, SopsConfigProvider.State.new!(app_name: :my_app, secret_file_path: "/path", sops_binary_path: "/usr/local/bin/sops")}
                           ]
                         ]
                      ]
                 """
  end

  @impl true
  @spec init(State.t()) :: State.t()
  def init(%State{} = state), do: state

  def init(_),
    do: raise(InitStateError)

  @impl true
  def load(config, %State{} = state) do
    # Need a right path for the secret file on release package

    sops_config =
      state
      |> Utils.check_sops_availability!()
      |> Utils.resolve_secret_file_location!()
      |> Utils.get_file_type()
      |> Utils.decrypt!()
      |> Utils.convert_to_map!()

    Config.Reader.merge(
      config,
      sops: sops_config
    )
  end
end
