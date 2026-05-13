# SopsConfigProvider

Decrypt secrets from sops file and set the config to your application on
runtime.

## Installation

The package can be installed
by adding `sops_config_provider` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sops_config_provider, "~> 0.4.0"}
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

## Options

Pass options as a map (second element of the tuple) in `config_providers`.

| Option | Type | Required | Default | Description |
|---|---|---|---|---|
| `app_name` | `atom` | yes | — | Your app name. Used to resolve `secret_file_path` via `Application.app_dir/2`. |
| `secret_file_path` | `string` | yes | — | Path to the SOPS-encrypted file relative to the app dir. Supports `.json`, `.yaml`, `.yml`. Accepts a comma-separated list of paths — files are decrypted in order, later values override earlier ones on key conflict. |
| `sops_binary_path` | `string` | no | `"sops"` | Path to the `sops` binary. Override if sops is not on `PATH`. |
| `execution_dir` | `string` | no | `"./"` | Working directory used when running `sops -d`. Relevant when sops resolves key config (e.g., `.sops.yaml`) relative to cwd. |
| `env_variables` | `[{string, string}]` | no | `[]` | Environment variables injected into the sops process. Useful for passing AWS/GCP credentials at runtime. |
| `mappings` | `map` | no | `%{}` | Remap flat secret keys into nested module configs. See [Mappings](#mappings) below. |
| `env_override` | `boolean` | no | `false` | Allow OS env vars to override decrypted SOPS values. See [Env Override](#env-override) below. |
| `config_env` | `atom` | no | `:prod` | Config environment. |

### Multiple secret files

Pass a comma-separated list to `secret_file_path` to load and merge multiple SOPS files. Files are decrypted in order — later files win on key conflict, unique keys from all files are preserved.

```elixir
{
  SopsConfigProvider,
  %{
    app_name: :my_app,
    secret_file_path: "priv/shared.enc.yaml, priv/app.enc.yaml"
  }
}
```

Given:

```yaml
# priv/shared.enc.yaml
sentry:
  dsn: "https://shared.sentry"
myapp:
  timeout: 5000
```

```yaml
# priv/app.enc.yaml
sentry:
  dsn: "https://app.sentry"
myapp:
  db_url: "ecto://user:pass@host/db"
```

Produces (app.enc.yaml wins on `sentry.dsn`, both files contribute unique keys):

```elixir
config :sentry, dsn: "https://app.sentry"
config :myapp, timeout: 5000, db_url: "ecto://user:pass@host/db"
```

### Mappings

`mappings` lets you nest a secret key under a specific module within an app's config.

Structure:

```elixir
%{
  app_atom => %{
    secret_key => {TargetModule, :nested_key}
  }
}
```

Example — map `:db_url` in `:my_app` into `{MyApp.Repo, :url}`:

```elixir
{
  SopsConfigProvider,
  %{
    app_name: :my_app,
    secret_file_path: "priv/secrets.yml",
    mappings: %{
      my_app: %{
        db_url: {MyApp.Repo, :url}
      }
    }
  }
}
```

Given this secret file:

```yaml
my_app:
  db_url: "ecto://user:pass@localhost/mydb"
  other_key: "value"
```

Produces:

```elixir
config :my_app, MyApp.Repo, url: "ecto://user:pass@localhost/mydb"
config :my_app, other_key: "value"
```

### Env Override

Set `env_override: true` to allow OS environment variables to override values from the SOPS file. Useful for emergency overrides or per-deploy flexibility without re-encrypting the secrets file.

**Naming convention:** `APP_KEY` — the app atom and config key joined with `_`, uppercased.

| YAML key | App | Derived env var |
|---|---|---|
| `api_key` | `stripity_stripe` | `STRIPITY_STRIPE_API_KEY` |
| `dsn` | `sentry` | `SENTRY_DSN` |
| `password` | `orca` | `ORCA_PASSWORD` |
| `webhook` | `slack` | `SLACK_WEBHOOK` |

Only flat atom keys are overridable. Nested module keys (set via `mappings`) are not derived and must be changed via the SOPS file.

An env var is ignored if it is not set or is an empty string — the SOPS value is used as-is.

```elixir
{
  SopsConfigProvider,
  %{
    app_name: :my_app,
    secret_file_path: "priv/secrets.yml",
    env_override: true,
    mappings: %{
      my_app: %{
        database_url: {MyApp.Repo, :url}
      }
    }
  }
}
```

With this config, setting `SENTRY_DSN=https://new-dsn` as an OS env var overrides the `sentry > dsn` value from the SOPS file at runtime. No re-encryption needed.

### env_variables example

Pass AWS credentials when the runtime environment doesn't have them on the system:

```elixir
{
  SopsConfigProvider,
  %{
    app_name: :my_app,
    secret_file_path: "priv/secrets.yml",
    env_variables: [
      {"AWS_ACCESS_KEY_ID", System.get_env("AWS_ACCESS_KEY_ID")},
      {"AWS_SECRET_ACCESS_KEY", System.get_env("AWS_SECRET_ACCESS_KEY")}
    ]
  }
}
