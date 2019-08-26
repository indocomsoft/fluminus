defmodule Fluminus.Constants do
  @moduledoc false

  def ocm_apim_subscription_key(_), do: "6963c200ca9440de8fa1eede730d8f7e"

  def api_base_url(:test), do: "http://localhost:8082"
  def api_base_url(_), do: "https://luminus.nus.edu.sg/v2/api/"

  def auth_base_uri(:test), do: "http://localhost:8081"
  def auth_base_uri(_), do: "https://luminus.nus.edu.sg"

  def ets_cassettes_table_name(_), do: :cassettes

  def fixtures_path(_), do: "test/fixtures/"
end
