defmodule SopsConfigProvider do
  @behaviour Config.Provider

  alias SopsConfigProvider.State
  alias SopsConfigProvider.Utils

  @sops_module Application.compile_env(
                 :sops_config_provider,
                 :sops_module,
                 SopsConfigProvider.Sops
               )

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
  def load(config, %State{mappings: mappings, env_override: env_override} = state) do
    sops_config =
      state
      |> @sops_module.check_sops_availability!()
      |> Utils.resolve_secret_file_location!()
      |> Utils.get_file_type()
      |> @sops_module.decrypt!()
      |> Utils.convert_to_keyword_list!()
      |> apply_mappings(mappings)
      |> apply_env_overrides(env_override)

    Config.Reader.merge(config, sops_config)
  end

  defp apply_mappings(sops_config, mappings) when map_size(mappings) == 0, do: sops_config

  defp apply_mappings(sops_config, mappings) do
    Enum.map(sops_config, fn {app, kw} ->
      app_mappings = Map.get(mappings, app, %{})
      {app, apply_app_mappings(kw, app_mappings)}
    end)
  end

  defp apply_app_mappings(kw, app_mappings) when map_size(app_mappings) == 0, do: kw

  defp apply_app_mappings(kw, app_mappings) do
    {mapped, unmapped} =
      Enum.split_with(kw, fn {key, _} -> Map.has_key?(app_mappings, key) end)

    module_configs =
      Enum.reduce(mapped, %{}, fn {key, value}, acc ->
        {module, nested_key} = Map.get(app_mappings, key)
        Map.update(acc, module, [{nested_key, value}], &[{nested_key, value} | &1])
      end)

    unmapped ++ Enum.map(module_configs, fn {mod, kw} -> {mod, kw} end)
  end

  defp apply_env_overrides(sops_config, false), do: sops_config

  defp apply_env_overrides(sops_config, true) do
    Enum.map(sops_config, fn {app, kw} ->
      {app, override_flat_keys(app, kw)}
    end)
  end

  defp override_flat_keys(app, kw) do
    Enum.map(kw, fn
      {key, val} when is_atom(key) ->
        env_var = derive_env_var(app, key)

        case System.get_env(env_var) do
          nil -> {key, val}
          "" -> {key, val}
          override -> {key, override}
        end

      other ->
        other
    end)
  end

  defp derive_env_var(app, key) do
    app_str = app |> Atom.to_string() |> String.upcase()
    key_str = key |> Atom.to_string() |> String.upcase()
    "#{app_str}_#{key_str}"
  end
end
