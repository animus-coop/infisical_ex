import Config

config :infisical_ex,
  api_url: "https://api.infisical.com",
  client_id: "",
  client_secret: "",
  environment: "production",
  workspace: "default"

import_config "#{config_env()}.exs"
