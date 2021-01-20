defmodule ProductsShopify.Images do
  require Logger

  def write(shopify_product) do
    shopify_product
    |> to_domain
    |> get_images_to_download
    |> download
  end

  defp to_domain(%{"node" => %{"handle" => handle, "images" => %{"edges" => images}}}) do
    Enum.map(images, to_domain(handle))
  end

  defp to_domain(handle) do
    fn %{"node" => %{"originalSrc" => src}} ->
      %{
        handle: handle,
        src: src,
        filepath: get_file_path(handle, src)
      }
    end
  end

  defp get_file_path(handle, src) do
    Path.join(get_file_dir(handle), get_file_name(src))
  end

  defp get_file_dir(handle) do
    Path.join(["products", handle])
  end

  @doc ~S"""
  Turn an URL into a filename.
  The `v` query string parameter is inserted into filename.

  **Only works with query strings that look like `?v=VERSION`.**

  ## Examples

      iex> ProductsShopify.Images.get_file_name("https://cdn.com/imgs/some-image.jpg")
      "some-image.jpg"
      iex> ProductsShopify.Images.get_file_name("https://cdn.com/imgs/some-image.jpg?v=1")
      "some-image__1.jpg"

  """
  def get_file_name(src) do
    src
    |> String.split("/")
    |> Enum.take(-1)
    |> Enum.at(0)
    |> String.split("?")
    |> (fn matches ->
          case matches do
            [filename, search] ->
              Path.rootname(filename) <>
                "__" <> String.replace(search, "v=", "") <> Path.extname(filename)

            [filename] ->
              filename
          end
        end).()
  end

  defp get_images_to_download(images) do
    Enum.filter(images, &image_exists/1)
  end

  defp image_exists(%{filepath: filepath}) do
    case File.exists?(filepath) do
      true ->
        Logger.debug("Image exists: #{filepath}")
        false

      false ->
        Logger.debug("Not found: #{filepath}")
        true
    end
  end

  defp download(%{src: src, filepath: filepath}) do
    Logger.info("Downloading #{filepath}")
    %HTTPoison.Response{body: body} = HTTPoison.get!(src)
    File.mkdir_p!(Path.dirname(filepath))
    File.write!(filepath, body)
  end

  defp download(images) do
    Enum.each(images, &download/1)
  end
end
