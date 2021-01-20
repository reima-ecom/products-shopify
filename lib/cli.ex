defmodule ProductsShopify.CLI do
  @moduledoc """
  Handle the command line parsing and the dispatch to
  the various functions
  """
  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  @doc """
  `argv` can be -h or --help, which returns :help.
  Return a tuple of `{ shop, token }`, or `:help` if help was given.
  """
  def parse_args(argv) do
    OptionParser.parse(argv,
      switches: [help: :boolean],
      aliases: [h: :help]
    )
    |> elem(1)
    |> args_to_domain
  end

  defp args_to_domain([shop, token]) do
    {shop, token}
  end

  defp args_to_domain(_) do
    :help
  end

  def process(:help) do
    IO.puts("""
    usage: products <shop> <token>
    """)

    System.halt(0)
  end

  def process({shop, token}) do
    ProductsShopify.import(shop, token)
  end
end
