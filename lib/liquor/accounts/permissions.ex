defmodule Liquor.Accounts.Permissions do
  @moduledoc """
  Role-based access control for the admin panel.

  Roles:
    - super_admin    → full access to everything
    - manager        → everything except users and settings
    - cashier        → dashboard, orders, customers, help
    - inventory_clerk → dashboard, products, categories, brands, inventory, help
  """

  @roles ~w(super_admin manager cashier inventory_clerk)

  @sections_by_role %{
    "super_admin" => :all,
    "manager" => ~w(dashboard products categories brands orders sales expenses customers inventory reports cash_registry help),
    "cashier" => ~w(dashboard orders customers cash_registry help),
    "inventory_clerk" => ~w(dashboard products categories brands inventory help)
  }

  @doc "Returns the list of valid role strings."
  def roles, do: @roles

  @doc "Returns true if the given user's role grants access to `section`."
  def can?(%{role: role}, section) when not is_nil(role) do
    case Map.get(@sections_by_role, role) do
      :all -> true
      sections when is_list(sections) -> to_string(section) in sections
      _ -> false
    end
  end

  def can?(_, _), do: false

  @doc "Human-readable label for a role."
  def role_label("super_admin"), do: "Super Admin"
  def role_label("manager"), do: "Manager"
  def role_label("cashier"), do: "Cashier"
  def role_label("inventory_clerk"), do: "Inventory Clerk"
  def role_label(_), do: "—"

  @doc "Tailwind badge classes for a role."
  def role_badge_class("super_admin"), do: "bg-purple-100 text-purple-700"
  def role_badge_class("manager"), do: "bg-blue-100 text-blue-700"
  def role_badge_class("cashier"), do: "bg-green-100 text-green-700"
  def role_badge_class("inventory_clerk"), do: "bg-amber-100 text-amber-700"
  def role_badge_class(_), do: "bg-gray-100 text-gray-400"
end
