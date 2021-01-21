defmodule ProductsShopify do
  def import(shop, token) do
    ProductsShopify.Stream.create(shop, token)
    |> Stream.each(&ProductsShopify.Product.write/1)
    |> Stream.each(&ProductsShopify.Images.write/1)
    |> Stream.run()
  end

  def import_time(shop, token, count) do
    {time, _result} =
      :timer.tc(fn -> Stream.run(Stream.take(ProductsShopify.import(shop, token), count)) end)

    IO.puts("Success in #{Float.round(time / 1_000_000)}s!")
  end
end
