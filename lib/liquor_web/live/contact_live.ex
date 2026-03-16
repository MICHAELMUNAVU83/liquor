defmodule LiquorWeb.ContactLive do
  use LiquorWeb, :live_view

  import LiquorWeb.ContactComponents

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"name" => "", "phone" => "", "email" => "", "message" => ""})

    {:ok,
     assign(socket,
       current_page: "contact",
       page_title: "Contact Us",
       form: form,
       submitted: false
     )}
  end

  @impl true
  def handle_event("validate", params, socket) do
    form =
      params
      |> Map.take(["name", "phone", "email", "message"])
      |> to_form(as: "contact")

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("reset_form", _params, socket) do
    form = to_form(%{"name" => "", "phone" => "", "email" => "", "message" => ""})
    {:noreply, assign(socket, form: form, submitted: false)}
  end

  def handle_event("submit", %{"name" => name} = params, socket) when name != "" do
    # In a real app: send email via Swoosh, persist to DB, etc.
    _safe_params = Map.take(params, ["name", "phone", "email", "message"])

    {:noreply,
     socket
     |> assign(submitted: true)
     |> put_flash(:info, "Thanks! We'll be in touch shortly.")}
  end

  def handle_event("submit", _params, socket) do
    {:noreply, put_flash(socket, :error, "Please fill in all required fields.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.contact_hero />
    <.contact_info_strip />

    <section id="contact-form" class="max-w-screen-xl mx-auto px-4 py-14">
      <div class="max-w-2xl">
        <%= if @submitted do %>
          <!-- Success state -->
          <div class="flex flex-col items-center justify-center py-20 text-center">
            <div class="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mb-6">
              <svg class="w-8 h-8 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h2 class="text-2xl font-black text-zinc-900 mb-2">Message Sent!</h2>
            <p class="text-sm text-zinc-500 mb-8">
              Thanks for reaching out. Someone from our team will be in touch shortly.
            </p>
            <button
              phx-click="reset_form"
              class="border border-amber-500 text-amber-700 hover:bg-amber-500 hover:text-white font-bold text-sm px-6 py-2.5 transition uppercase tracking-widest"
            >
              Send Another Message
            </button>
          </div>
        <% else %>
          <h2 class="text-2xl font-black text-zinc-900 mb-2">Information Request</h2>
          <p class="text-sm text-zinc-500 mb-10 leading-relaxed">
            For more information and how we can meet your needs, please fill out the form below
            and someone from our team will be in touch.
          </p>

          <form phx-change="validate" phx-submit="submit" class="space-y-8">
            <!-- Name + Phone -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-8">
              <div class="flex flex-col gap-1">
                <label class="text-sm text-zinc-600">
                  Name <span class="text-zinc-400">*</span>
                </label>
                <input
                  type="text"
                  name="name"
                  value={@form["name"].value}
                  required
                  class="border-0 border-b border-zinc-300 focus:border-amber-500 py-2 text-sm text-zinc-800 focus:outline-none bg-transparent"
                />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-sm text-zinc-600">
                  Phone Number <span class="text-zinc-400">*</span>
                </label>
                <input
                  type="tel"
                  name="phone"
                  value={@form["phone"].value}
                  required
                  class="border-0 border-b border-zinc-300 focus:border-amber-500 py-2 text-sm text-zinc-800 focus:outline-none bg-transparent"
                />
              </div>
            </div>

            <!-- Email -->
            <div class="flex flex-col gap-1">
              <label class="text-sm text-zinc-600">
                Email <span class="text-zinc-400">*</span>
              </label>
              <input
                type="email"
                name="email"
                value={@form["email"].value}
                required
                class="border-0 border-b border-zinc-300 focus:border-amber-500 py-2 text-sm text-zinc-800 focus:outline-none bg-transparent w-full"
              />
            </div>

            <!-- Message -->
            <div class="flex flex-col gap-1">
              <textarea
                name="message"
                rows="5"
                placeholder="Say something..."
                class="border-0 border-b border-zinc-300 focus:border-amber-500 py-2 text-sm text-zinc-800 focus:outline-none placeholder-zinc-400 bg-transparent w-full resize-none"
              ><%= @form["message"].value %></textarea>
            </div>

            <!-- Submit -->
            <div>
              <button
                type="submit"
                class="bg-orange-500 hover:bg-orange-600 text-white font-bold text-sm px-8 py-3 uppercase tracking-widest transition"
              >
                Send Message
              </button>
            </div>
          </form>
        <% end %>
      </div>
    </section>

    <.contact_map />
    """
  end
end
