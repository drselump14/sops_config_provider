VERSION 0.6

ARG ELIXIR=1.14.1
ARG OTP=25.1.2
FROM hexpm/elixir:$ELIXIR-erlang-$OTP-alpine-3.16.2
WORKDIR /src

setup-mix:
  RUN apk add --no-progress --update git build-base
  ENV ELIXIR_ASSERT_TIMEOUT=10000

  RUN mix local.hex --force && mix local.rebar --force

deps-get:
  FROM +setup-mix
  COPY mix.exs mix.lock ./
  COPY config config
  RUN mix do deps.get, deps.compile
  RUN MIX_ENV=test mix deps.compile

  RUN mix hex.audit
  RUN mix deps.unlock --check-unused

  RUN mix dialyzer --plt
  SAVE ARTIFACT /src/deps
  SAVE ARTIFACT /src/_build
  SAVE IMAGE --push ghcr.io/drselump14/sops_config_provider:deps-plts

linter:
  FROM +setup-mix
  BUILD +deps-get
  COPY +deps-get/deps /src/deps
  COPY +deps-get/_build /src/_build

  COPY . .

  RUN mix deps.audit
  RUN mix format --dry-run --check-formatted
  RUN mix credo --strict
  RUN mix compile --all-warnings --warnings-as-errors
  RUN mix dialyzer --halt-exit-status
  RUN mix gradient

  SAVE IMAGE --push ghcr.io/drselump14/sops_config_provider:linter
  # TODO add Documentation
  # RUN mix doctor

test:
  FROM +setup-mix
  BUILD +deps-get
  COPY +deps-get/deps /src/deps
  COPY +deps-get/_build /src/_build

  # Coveralls needs these environment variables to post coverage report
  ARG GITHUB_SHA
  ARG GITHUB_REF
  ARG GITHUB_TOKEN
  ARG GITHUB_EVENT_NAME

  # Need to copy the event.json from github action host container to tmp/event.json
  ARG GITHUB_EVENT_PATH=/src/tmp/event.json

  COPY . .

  RUN mix coveralls.github
  SAVE ARTIFACT /src
  SAVE IMAGE --push ghcr.io/drselump14/sops_config_provider:compile_test
