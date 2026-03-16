defmodule Liquor.Accounts do
  @moduledoc "Accounts context – users and addresses."

  import Ecto.Query
  alias Liquor.Repo
  alias Liquor.Accounts.{User, Address}

  # ---------------------------------------------------------------------------
  # Users
  # ---------------------------------------------------------------------------

  def list_users(opts \\ []) do
    base = from u in User, order_by: [desc: u.inserted_at]

    base
    |> maybe_search_users(opts[:search])
    |> Repo.all()
  end

  defp maybe_search_users(q, nil),  do: q
  defp maybe_search_users(q, ""),   do: q
  defp maybe_search_users(q, term) do
    t = "%#{term}%"
    where(q, [u], ilike(u.email, ^t) or ilike(u.first_name, ^t) or ilike(u.last_name, ^t))
  end

  def get_user(id), do: Repo.get(User, id)
  def get_user!(id), do: Repo.get!(User, id)
  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def create_user(attrs), do: %User{} |> User.changeset(attrs) |> Repo.insert()
  def update_user(%User{} = u, attrs), do: u |> User.admin_changeset(attrs) |> Repo.update()
  def delete_user(%User{} = u), do: Repo.delete(u)
  def change_user(%User{} = u, attrs \\ %{}), do: User.changeset(u, attrs)

  def authenticate(email, password) do
    hash = :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)

    case Repo.get_by(User, email: email, password_hash: hash, is_active: true) do
      nil  -> {:error, :invalid_credentials}
      user -> {:ok, user}
    end
  end

  def count_users, do: Repo.aggregate(User, :count)

  def list_users_with_stats(opts \\ []) do
    import Ecto.Query
    alias Liquor.Orders.Order

    base =
      from u in User,
        left_join: o in Order, on: o.user_id == u.id,
        group_by: u.id,
        select: %{
          id: u.id,
          first_name: u.first_name,
          last_name: u.last_name,
          email: u.email,
          phone: u.phone,
          is_active: u.is_active,
          inserted_at: u.inserted_at,
          order_count: count(o.id),
          lifetime_value: coalesce(sum(fragment("CASE WHEN ? = 'paid' THEN ? ELSE 0 END", o.payment_status, o.total_amount)), ^Decimal.new("0"))
        },
        order_by: [desc: u.inserted_at]

    base
    |> maybe_search_with_stats(opts[:search])
    |> Repo.all()
  end

  defp maybe_search_with_stats(q, nil),  do: q
  defp maybe_search_with_stats(q, ""),   do: q
  defp maybe_search_with_stats(q, term) do
    t = "%#{term}%"
    where(q, [u], ilike(u.email, ^t) or ilike(u.first_name, ^t) or ilike(u.last_name, ^t))
  end

  # ---------------------------------------------------------------------------
  # Addresses
  # ---------------------------------------------------------------------------

  def list_addresses_for(user_id) do
    Repo.all(from a in Address, where: a.user_id == ^user_id, order_by: [desc: a.is_default])
  end

  def create_address(attrs), do: %Address{} |> Address.changeset(attrs) |> Repo.insert()
  def update_address(%Address{} = a, attrs), do: a |> Address.changeset(attrs) |> Repo.update()
  def delete_address(%Address{} = a), do: Repo.delete(a)
end
