defmodule Liquor.StoreConfig do
  @moduledoc """
  Single source of truth for The Mint Liquor Store branding and contact details.
  Update the values here and they propagate everywhere on the site.
  """

  def name,              do: "The Mint Liquor Store"
  def short_name,        do: "The Mint"
  def tagline,           do: "Liquor Store"
  def phone,             do: "+254 700 123 456"
  def email,             do: "info@themintliquorstore.co.ke"
  def store_address,     do: "Lumumba Drive, TRM, Thika Road, Nairobi"
  def hq_address,        do: "TRM Mall, Thika Road, Nairobi, Kenya"
  def hours_weekday,     do: "Monday – Friday,  9:00 am – 9:00 pm"
  def hours_saturday,    do: "Saturday,  9:00 am – 10:00 pm"
  def hours_sunday,      do: "Sunday,  10:00 am – 9:00 pm"
  def map_query,         do: "TRM+Mall+Thika+Road+Nairobi+Kenya"
  def currency_symbol,   do: "KSh"
  def currency_code,     do: "KES"
  def free_ship_threshold, do: "10000.00"
  def shipping_cost,     do: "300.00"
end
