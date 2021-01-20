defmodule ProductsShopify.Stream do
  use PlumberGirl

  def create(shop, token) do
    Stream.resource(
      fn -> {shop, token, false, true} end,
      &get_next_products/1,
      fn _ -> nil end
    )
  end

  def get_next_products({shop, token, cursor, true}) do
    case HTTPoison.post(graphql_url(shop), gql_products(5, cursor), headers(token)) >>>
           get_body >>>
           Poison.decode() do
      {:ok,
       %{
         "data" => %{
           "products" => %{
             "edges" => products,
             "pageInfo" => %{"hasNextPage" => has_next_page}
           }
         }
       }} ->
        {products, {shop, token, List.last(products)["cursor"], has_next_page}}

      _ ->
        {:halt, nil}
    end
  end

  def get_next_products({_shop, _token, _cursor, false}), do: {:halt, nil}

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

  def get_pagination(count, false), do: "first: #{count}"
  def get_pagination(count, cursor), do: get_pagination(count, false) <> ~s/, after: "#{cursor}"/

  def gql_products(count \\ 5, cursor \\ false) do
    """
    {
      products(#{get_pagination(count, cursor)}) {
        pageInfo {
          hasNextPage
        }
        edges {
          cursor
          node {
            id
            handle
            title
            availableForSale
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
              minVariantPrice { amount }
              maxVariantPrice { amount }
            }
            compareAtPriceRange {
              maxVariantPrice { amount }
            }
            options {
              name
              values
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

  defp get_body(%{status_code: 200, body: body}), do: {:ok, body}

  defp get_body(%{status_code: status_code}) do
    {
      :error,
      "HTTP status code #{status_code}"
    }
  end
end
