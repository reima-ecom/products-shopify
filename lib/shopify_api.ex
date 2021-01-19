defmodule ProductsShopify.ShopifyApi do
  use PlumberGirl

  def stream(shop, token) do
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

  def fetch_time(shop, token) do
    {time, _result} = :timer.tc(fn -> Stream.run(fetch(shop, token)) end)
    IO.puts("Success in #{Float.round(time / 1_000_000)}s!")
  end

  def fetch(shop, token) do
    stream(shop, token)
    # |> Stream.take(7)
    |> Stream.map(&to_domain/1)
    |> Stream.map(&serialize/1)
    |> Stream.map(&write/1)
  end

  def serialize(product) do
    {
      product,
      Poison.encode!(product)
    }
  end

  def write({product, _product_dto}) do
    IO.puts("Writing #{product.handle}")
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

  def to_domain(%{
        "node" => product
      }) do
    {product, %{}}
    |> get_product_basics()
    |> get_product_info()
    |> get_product_options()
    |> extract_domain_product()
  end

  def get_product_basics({shopify_product, domain_product}) do
    %{
      "handle" => handle,
      "title" => title,
      "availableForSale" => available,
      "priceRange" => %{
        "maxVariantPrice" => %{"amount" => max_price},
        "minVariantPrice" => %{"amount" => min_price}
      },
      "compareAtPriceRange" => %{
        "maxVariantPrice" => %{"amount" => compare_at_price}
      }
    } = shopify_product

    {
      shopify_product,
      Map.merge(domain_product, %{
        handle: handle,
        title: title,
        available: available,
        # these need to be converted to float
        has_price_range: max_price > min_price,
        compare_at_price: compare_at_price
      })
    }
  end

  def get_product_info({
        shopify_product,
        domain_product
      }) do
    %{
      "descriptionHtml" => description_html
    } = shopify_product

    {
      shopify_product,
      Map.merge(domain_product, %{
        description_html: description_html
      })
    }
  end

  def get_product_options({
        shopify_product,
        domain_product
      }) do
    %{
      "options" => options
    } = shopify_product

    {
      shopify_product,
      Map.merge(domain_product, %{
        options: options
      })
    }
  end

  def extract_domain_product({_, domain_product}), do: domain_product

  defp get_body(%{status_code: 200, body: body}), do: {:ok, body}

  defp get_body(%{status_code: status_code}) do
    {
      :error,
      "HTTP status code #{status_code}"
    }
  end
end
