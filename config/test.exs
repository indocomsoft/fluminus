use Mix.Config

config :fluminus,
  port: 8081,
  fixtures_path: "test/fixtures/",
  auth_base_uri: "http://localhost:8081",
  discovery_path: "/v2/auth/.well-known/openid-configuration",
  client_id: "verso",
  scope:
    "profile email role openid lms.read calendar.read lms.delete lms.write calendar.write gradebook.write offline_access",
  response_type: "id_token token code",
  redirect_uri: "https://luminus.nus.edu.sg/auth/callback",
  api_base_url: "http://localhost:8082",
  ocm_apim_subscription_key: "6963c200ca9440de8fa1eede730d8f7e",
  ets_cassettes_table_name: :cassettes
