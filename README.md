# SopsConfigProvider

Decrypt and load secrets from sops file to your application config.

## Installation

The package can be installed
by adding `sops_config_provider` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sops_config_provider, "~> 0.1.0"}
  ]
end
```

## Usage

**[ATTENTION] Please make sure that you have sops installed, and proper permission
to encrypt and decrypt the file. See [SOPS docs](https://github.com/mozilla/sops)
for sops intallation and setup**

After the installation, you need to add the provider into `def project` section in
`mix.exs`.

```elixir
      releases: [
        change_with_your_app_name: [
          config_providers: [
            {
              SopsConfigProvider,
              %{
                app_name: :change_with_your_app_name,
                secret_file_path: "priv/secrets.yml" # I'd recommend to put
                # the secrets inside the priv directory, as it automatically get
                # copied on release
              }
            }
          ]
        ]
      ]
```

In your release, the secrets content would be loaded into `config :sops`,
which can be called with `Application.get_env/2`.

For example, if you have secrets config in yaml as below

```yaml
# priv/secrets.yml
hello: world
```

Then, you can fetch the value with `Application.get_env(:sops, :hello) #
=> "world"`
