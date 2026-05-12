defmodule SopsConfigProviderTest do
  use ExUnit.Case, async: false
  alias SopsConfigProvider.InitStateError
  alias SopsConfigProvider.Sops.SopsDecryptError
  alias SopsConfigProvider.State

  import Hammox

  doctest SopsConfigProvider

  @sentry_dsn "https://sentry.io"
  @yaml """
    sentry:
      dsn: #{@sentry_dsn}
  """

  @app_name :sops_config_provider
  @secret_file_path "priv/test_samples/test.yaml"

  describe "init/1" do
    test "when the argument is map" do
      state = %{
        app_name: :my_app,
        secret_file_path: "/file_path"
      }

      assert(%State{} = SopsConfigProvider.init(state))
    end

    test "when the argument is State struct, should return state" do
      state =
        State.new!(
          app_name: :my_app,
          secret_file_path: "/file_path"
        )

      assert(SopsConfigProvider.init(state) == state)
    end

    test "should raise InitStateError when the parameter is not State" do
      assert_raise(InitStateError, fn -> SopsConfigProvider.init("hoge") end)
    end
  end

  describe "load/2" do
    setup %{} do
      init_state =
        State.new!(
          app_name: @app_name,
          secret_file_path: @secret_file_path,
          sops_binary_path: "sops"
        )

      config = [b: "2"]

      %{init_state: init_state, config: config}
    end

    test "when success", %{init_state: init_state, config: config} do
      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml) |> State.ensure_type!()
      end)

      refute config |> Keyword.has_key?(:sentry)

      assert new_config = config |> SopsConfigProvider.load(init_state)

      assert new_config |> Keyword.has_key?(:sentry)
      assert new_config[:b] == "2"
      assert new_config[:sentry][:dsn] == @sentry_dsn
    end

    test "when failed", %{init_state: init_state, config: config} do
      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn _state ->
        raise SopsDecryptError, "error"
      end)

      assert_raise SopsDecryptError, fn -> config |> SopsConfigProvider.load(init_state) end
    end
  end

  describe "load/2 with mappings" do
    @yaml_with_mappings """
      myapp:
        database_url: "ecto://user:pass@host/db"
        secret_key_base: "abc123"
        other_key: "other_value"
      sentry:
        dsn: #{@sentry_dsn}
    """

    setup %{} do
      init_state =
        State.new!(
          app_name: @app_name,
          secret_file_path: @secret_file_path,
          sops_binary_path: "sops",
          mappings: %{
            myapp: %{
              database_url: {MyApp.Repo, :url},
              secret_key_base: {MyApp.Endpoint, :secret_key_base}
            }
          }
        )

      config = []
      %{init_state: init_state, config: config}
    end

    test "maps flat keys to nested module config", %{init_state: init_state, config: config} do
      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_with_mappings) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:myapp][MyApp.Repo][:url] == "ecto://user:pass@host/db"
      assert new_config[:myapp][MyApp.Endpoint][:secret_key_base] == "abc123"
      assert new_config[:myapp][:other_key] == "other_value"
      assert new_config[:sentry][:dsn] == @sentry_dsn
    end

    test "unmapped keys remain flat", %{init_state: init_state, config: config} do
      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_with_mappings) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:myapp][:other_key] == "other_value"
    end

    test "apps without mappings are unaffected", %{init_state: init_state, config: config} do
      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_with_mappings) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:sentry][:dsn] == @sentry_dsn
    end

    test "empty mappings leaves config unchanged", %{config: config} do
      init_state =
        State.new!(
          app_name: @app_name,
          secret_file_path: @secret_file_path,
          sops_binary_path: "sops",
          mappings: %{}
        )

      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_with_mappings) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:myapp][:database_url] == "ecto://user:pass@host/db"
      assert new_config[:myapp][:secret_key_base] == "abc123"
    end
  end

  describe "load/2 with env_override: true" do
    @yaml_for_override """
      myapp:
        api_key: "sops_value"
        other: "unchanged"
      sentry:
        dsn: "sops_dsn"
    """

    setup %{} do
      init_state =
        State.new!(
          app_name: @app_name,
          secret_file_path: @secret_file_path,
          sops_binary_path: "sops",
          env_override: true
        )

      %{init_state: init_state, config: []}
    end

    test "env var overrides sops value", %{init_state: init_state, config: config} do
      System.put_env("MYAPP_API_KEY", "env_value")
      on_exit(fn -> System.delete_env("MYAPP_API_KEY") end)

      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_for_override) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:myapp][:api_key] == "env_value"
    end

    test "sops value used when env var not set", %{init_state: init_state, config: config} do
      System.delete_env("MYAPP_API_KEY")

      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_for_override) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:myapp][:api_key] == "sops_value"
    end

    test "empty env var does not override", %{init_state: init_state, config: config} do
      System.put_env("MYAPP_API_KEY", "")
      on_exit(fn -> System.delete_env("MYAPP_API_KEY") end)

      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_for_override) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:myapp][:api_key] == "sops_value"
    end

    test "unset env var leaves other keys unchanged", %{init_state: init_state, config: config} do
      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_for_override) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:myapp][:other] == "unchanged"
      assert new_config[:sentry][:dsn] == "sops_dsn"
    end

    test "env_override: false skips override", %{config: config} do
      System.put_env("MYAPP_API_KEY", "env_value")
      on_exit(fn -> System.delete_env("MYAPP_API_KEY") end)

      init_state =
        State.new!(
          app_name: @app_name,
          secret_file_path: @secret_file_path,
          sops_binary_path: "sops",
          env_override: false
        )

      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml_for_override) |> State.ensure_type!()
      end)

      new_config = SopsConfigProvider.load(config, init_state)

      assert new_config[:myapp][:api_key] == "sops_value"
    end
  end
end
