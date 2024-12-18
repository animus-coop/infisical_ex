# InfisicalEx

**Simple secrets client for infisical project**


## Installation

First, add infisical_ex to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:infisical_ex, "~> 0.1.0"}
  ]
end
```

and run `$ mix deps.get`.

## Config
Add the following configs:
```elixir
config :infisical_ex,
  api_url: "https://secrets.yourproject.com/api",
  client_id: System.get_env("SECRETS_CLIENT_ID"),
  client_secret: System.get_env("SECRETS_CLIENT_SECRET"),
  environment: config_env(),
  workspace: System.get_env("SECRETS_WORKSPACE")
```

## Usage

##### Get all secrets

```elixir
# Specifying env
iex> InfisicalEx.get_all_secrets("prod")
{:ok,
 %{
   "DATABASE_URL" => "ecto://postgres:******@localhost:5432/postgres",
   "GUARDIAN_SECRET_KEY" => "**************",
   "METRICS_PASSWORD" => "**************",
   "POSTGRES_PASSWORD" => "**************",
   "RELEASE_COOKIE" => "**************",
   "S3_ACCESS_KEY" => "**************",
   "S3_SECRET_KEY" => "**************",
   "SECRET_KEY_BASE" => "**************",
   "TURNSTILE_SECRET_KEY" => "**************",
   "TURNSTILE_SITE_KEY" => "**************"
 }}

# Using the config environment
iex> InfisicalEx.get_all_secrets()
{:ok,
 %{
   "DATABASE_URL" => "ecto://postgres:******@localhost:5432/postgres",
   "GUARDIAN_SECRET_KEY" => "**************",
   "METRICS_PASSWORD" => "**************",
   "POSTGRES_PASSWORD" => "**************",
   "RELEASE_COOKIE" => "**************",
   "S3_ACCESS_KEY" => "**************",
   "S3_SECRET_KEY" => "**************",
   "SECRET_KEY_BASE" => "**************",
   "TURNSTILE_SECRET_KEY" => "**************",
   "TURNSTILE_SITE_KEY" => "**************"
 }}
```

##### Get an specific secret
```elixir
# Specifying env
iex> InfisicalEx.get_secret("TURNSTILE_SECRET_KEY", "prod")
{:ok, "********"}

# Using default env in config
iex> InfisicalEx.get_secret("TURNSTILE_SECRET_KEY")
{:ok, "********"}
```

## In runtime config
```elixir
Application.ensure_all_started(:hackney)
{:ok, secrets} = InfisicalEx.get_all_secrets(config_env())

# S3
config :acme,
  s3: [
    bucket: System.get_env("S3_BUCKET"),
    region: System.get_env("S3_REGION"),
    hostname: System.get_env("S3_HOSTNAME"),
    access_key_id: secrets["S3_ACCESS_ID"],
    secret_access_key: secrets["S3_SECRET_KEY"]
  ]

```


## License
Copyright © 2024-present Julian Somoza @ Animus Coop <info@animus.com.ar>

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the LICENSE file for more details.