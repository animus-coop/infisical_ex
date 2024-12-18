defmodule InfisicalEx do
  @moduledoc """
  InfisicalEx is a plugin for securely connecting and retrieving secrets from Infisical.

  This module provides functionality to interact with the Infisical API,
  allowing Elixir applications to fetch and manage secrets seamlessly.
  """

  @doc """
  Retrieves a secret by its name from Infisical.
  Takes the environment from the config.

  ## Example

      iex> InfisicalEx.get_secret("DATABASE_PASSWORD")
      {:ok, "secret"}

      iex> InfisicalEx.get_secret("BAD_KEY")
      {:error,
      %{
        "error" => "NotFound",
        "message" => "Secret with name 'DATABASE_URL2' not found",
        "reqId" => "req-90znAsRyfXUcUG",
        "statusCode" => 404
      }}

  """
  @spec get_secret(String.t()) :: {:ok, String.t()} | {:error, map()}
  def get_secret(secret_name), do: get_secret(secret_name, environment())

  @doc """
  Retrieves a secret by its name from Infisical.
  Takes the environment from params.

  ## Example

      iex> InfisicalEx.get_secret("DATABASE_PASSWORD", "prod")
      {:ok, "secret"}

      iex> InfisicalEx.get_secret("DATABASE_PASSWORD", "bad_env")
      {:error,
      %{
        "error" => "GetSecretByName",
        "message" => "Folder with path '/' in environment with slug 'bad_env' not found",
        "reqId" => "req-nzxiNt3LAAn0q4",
        "statusCode" => 404
      }}
  """
  @spec get_secret(String.t(), String.t()) :: {:ok, String.t()} | {:error, map()}
  def get_secret(secret_name, env) do
    with {:ok, token} <- get_token(),
         response <-
           HTTPoison.get(
             "#{api_url()}/v3/secrets/raw/#{secret_name}?environment=#{env}&workspaceSlug=#{workspace()}",
             [{"Authorization", "Bearer #{token}"}]
           ),
         {:ok, %{"secret" => %{"secretValue" => secret_value}}} <- handle_response(response) do
      {:ok, secret_value}
    else
      {:error, :bad_token} ->
        case fetch_token() do
          {:ok, _token} -> get_secret(secret_name, env)
          {:error, error} -> {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Retrieves all secrets available for the project.
  Use the environment from the given param.

  ## Example
      iex> InfisicalEx.get_all_secrets("dev")
      {:ok, %{
        "DATABASE_URL" => "ecto://postgres:xxxx@localhost:5432/postgres",
        "GUARDIAN_SECRET_KEY" => "xxxxx",
        "POSTGRES_PASSWORD" => "xxxx!",
        "RELEASE_COOKIE" => "xxxxx",
        "S3_ACCESS_KEY" => "xxxxx",
        "S3_SECRET_KEY" => "xxxx",
        "SECRET_KEY_BASE" => "xxxxx",
        "TURNSTILE_SECRET_KEY" => "xxx",
        "TURNSTILE_SITE_KEY" => "xxxx"
      }}
  """
  @spec get_all_secrets() :: {:ok, list()} | {:error, String.t()}
  def get_all_secrets(), do: get_all_secrets(environment())

  @doc """
  Retrieves all secrets available for the project.

  ## Example
      iex> InfisicalEx.get_all_secrets()
      {:ok, %{
        "DATABASE_URL" => "ecto://postgres:xxxx@localhost:5432/postgres",
        "GUARDIAN_SECRET_KEY" => "xxxxx",
        "POSTGRES_PASSWORD" => "xxxx!",
        "RELEASE_COOKIE" => "xxxxx",
        "S3_ACCESS_KEY" => "xxxxx",
        "S3_SECRET_KEY" => "xxxx",
        "SECRET_KEY_BASE" => "xxxxx",
        "TURNSTILE_SECRET_KEY" => "xxx",
        "TURNSTILE_SITE_KEY" => "xxxx"
      }}
  """
  @spec get_all_secrets(String.t()) :: {:ok, list()} | {:error, String.t()}
  def get_all_secrets(env) do
    with {:ok, token} <- get_token(),
         response <-
           HTTPoison.get(
             "#{api_url()}/v3/secrets/raw?environment=#{env}&workspaceSlug=#{workspace()}",
             [
               {"Authorization", "Bearer #{token}"}
             ]
           ),
         {:ok, %{"secrets" => secrets}} <- handle_response(response) do
      secrets =
        Enum.reduce(secrets, %{}, fn secret, acc ->
          Map.put(acc, secret["secretKey"], secret["secretValue"])
        end)

      {:ok, secrets}
    else
      {:error, :bad_token} ->
        case fetch_token() do
          {:ok, _token} -> get_all_secrets(env)
          {:error, error} -> {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec get_token() :: {:ok, String.t()} | {:error, String.t()}
  defp get_token() do
    :ets.whereis(__MODULE__)
    |> maybe_create_ets_table()

    case :ets.lookup(__MODULE__, :token) do
      [] ->
        case fetch_token() do
          {:ok, token} -> {:ok, token}
          {:error, error} -> {:error, error}
        end

      [{:token, token}] ->
        {:ok, token}
    end
  end

  @spec fetch_token() :: {:ok, String.t()} | {:error, any()}
  defp fetch_token() do
    url = "#{api_url()}/v1/auth/universal-auth/login"
    body = {:form, [{:clientSecret, client_secret()}, {:clientId, client_id()}]}

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Jason.decode!(body)

        :ets.insert(__MODULE__, {:token, response["accessToken"]})
        {:ok, response["accessToken"]}

      {:ok, %HTTPoison.Response{body: body}} ->
        {:error, Jason.decode!(body)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp api_url(), do: Application.get_env(:infisical_ex, :api_url, "https://api.infisical.com")

  defp environment(), do: Application.get_env(:infisical_ex, :environment)

  defp workspace(), do: Application.get_env(:infisical_ex, :workspace)

  defp client_secret() do
    Application.get_env(:infisical_ex, :client_secret, nil)
  end

  defp client_id() do
    Application.get_env(:infisical_ex, :client_id, nil)
  end

  defp maybe_create_ets_table(:undefined), do: :ets.new(__MODULE__, [:set, :named_table, :public])
  defp maybe_create_ets_table(_), do: :ok

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}),
    do: {:ok, Jason.decode!(body)}

  defp handle_response({:ok, %HTTPoison.Response{status_code: code, body: body}}) do
    case Jason.decode!(body) do
      %{
        "error" => "TokenError"
      } ->
        {:error, :bad_token}

      body ->
        {:error, %{status: code, body: body}}
    end
  end

  defp handle_response({:error, %HTTPoison.Error{reason: reason}}),
    do: {:error, %{reason: reason}}
end
