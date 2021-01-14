defmodule ProductsShopify.ShopifyApi do
  def fetch(shop, token) do
    graphql_url(shop)
    |> HTTPoison.post(gql_products(), headers(token))
    |> handle_response
    |> (fn {:ok, gql} -> Enum.map(gql["data"]["products"]["edges"], &to_domain/1) end).()
  end

  @spec headers(String.t()) :: [{String.t(), String.t()}, ...]
  def headers(token),
    do: [
      {"X-Shopify-Storefront-Access-Token", token},
      {"Content-Type", "application/graphql"},
      {"Accept", "application/json"}
    ]

  @spec graphql_url(String.t()) :: String.t()
  def graphql_url(shop) do
    "https://#{shop}.myshopify.com/api/2021-01/graphql.json"
  end

  def gql_products() do
    """
    {
      products(first: 5) {
        edges {
          node {
            id
            handle
            title
            descriptionHtml
            tags
            images(first: 50) {
              edges {
                node {
                  id
                  originalSrc
                }
              }
            }
            priceRange {
              minVariantPrice { currencyCode }
            }
            variants(first: 50) {
              edges {
                node {
                  id
                  availableForSale
                  compareAtPrice
                  price
                  image { originalSrc }
                  selectedOptions {
                    name
                    value
                  }
                }
              }
            }
          }
        }
      }
    }
    """
  end

  def handle_response({_, %{status_code: status_code, body: body}}) do
    {
      status_code |> check_status,
      body |> Poison.decode!()
    }
  end

  def to_domain(shopify_product) do
    %{
      handle: shopify_product["node"]["handle"]
    }
  end

  defp check_status(200), do: :ok
  defp check_status(_), do: :error
end
