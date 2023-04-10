# SopsConfigProvider

Decrypt secrets from sops file and set the config to your application on
runtime.

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

The config provider will decrypt the secrets and set the config like you do in
runtime.exs

For example, if you have secrets config in yaml as below

```yaml
# priv/secrets.yml
sentry:
    dsn: "https://sentry.io"
```

It'll set the value below and app boot like on `runtime.exs`

```elixir
config :sentry, dsn: "http://sentry.io"
```
