defmodule LiquorWeb.Helpers do
  @doc """
  Formats a Decimal (or nil) as a money string with 2 decimal places
  and comma thousands separators. e.g. 1234567.8 -> "1,234,567.80"
  """
  def fmt(nil), do: "0.00"

  def fmt(d) do
    rounded = Decimal.round(d || Decimal.new("0"), 2)
    str = Decimal.to_string(rounded)

    {sign, digits} =
      if String.starts_with?(str, "-"),
        do: {"-", String.slice(str, 1..-1//1)},
        else: {"", str}

    [int_part, dec_part] =
      case String.split(digits, ".") do
        [i, dec] -> [i, dec]
        [i] -> [i, "00"]
      end

    formatted_int =
      int_part
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.join/1)
      |> Enum.join(",")
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.join()

    "#{sign}#{formatted_int}.#{dec_part}"
  end
end
