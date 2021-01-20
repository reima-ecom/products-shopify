defmodule ProductsShopify.Product do
  require Logger

  def write(shopify_product) do
    shopify_product
    |> to_domain()
    |> serialize()
    |> write_to_disk()
  end

  def to_domain(%{
        "node" => product
      }) do
    {product, %{}}
    |> translate_wrapper(&get_product_basics/1)
    |> translate_wrapper(&get_product_info/1)
    |> translate_wrapper(&get_product_options/1)
    |> extract_domain_product()
  end

  def get_product_basics(%{
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
      }) do
    %{
      handle: handle,
      title: title,
      available: available,
      # these need to be converted to float
      has_price_range: max_price > min_price,
      compare_at_price: compare_at_price
    }
  end

  def get_product_info(%{
        "descriptionHtml" => description_html
      }) do
    %{
      description_html: description_html
    }
  end

  def get_product_options(%{
        "options" => options
      }) do
    %{
      options: options
    }
  end

  def translate_wrapper({shopify_product, domain_product}, translator) do
    {
      shopify_product,
      Map.merge(domain_product, translator.(shopify_product))
    }
  end

  def extract_domain_product({_, domain_product}), do: domain_product

  def serialize(product) do
    {
      product,
      Poison.encode!(product)
    }
  end

  defp get_file_path(handle), do: Path.join(["products", handle, "index.html"])

  def write_to_disk({%{handle: handle}, product_dto}) do
    filepath = get_file_path(handle)
    Logger.info("Writing #{filepath}")

    filepath
    |> Path.dirname()
    |> File.mkdir_p!()

    filepath
    |> File.write!(product_dto)
  end
end
