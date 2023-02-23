import Config

if Mix.env() == :dev do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix hex.audit"},
          {:cmd, "mix deps.unlock --check-unused"},
          {:cmd, "mix deps.audit"},
          {:cmd, "mix compile --warning-as-errors"},
          {:cmd, "mix format --check-formatted"},
          {:cmd, "mix credo --strict suggest"}
        ]
      ],
      pre_push: [
        tasks: [
          {:cmd, "mix gradient"},
          {:cmd, "mix dialyzer"},
          {:cmd, "mix test --color"},
          {:cmd, "echo 'success!'"}
        ]
      ]
    ]
end
