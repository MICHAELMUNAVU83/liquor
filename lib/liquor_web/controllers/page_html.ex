defmodule LiquorWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use LiquorWeb, :html

  import LiquorWeb.HomeComponents
  import LiquorWeb.ShopComponents
  import LiquorWeb.AboutComponents
  import LiquorWeb.ContactComponents

  embed_templates "page_html/*"
end
