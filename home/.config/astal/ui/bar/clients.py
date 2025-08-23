from gi.repository import Gtk, Pango, AstalHyprland

class ClientButton(Gtk.Button):
    def __init__(self, c):
        super().__init__(
            child = Gtk.Label(
                visible = True,
                max_width_chars = 15,
                ellipsize = Pango.EllipsizeMode.END,
                label = c.get_initial_class()
            )
        )

        hyprland = AstalHyprland.get_default()

        def on_focused_client(*_):
            if c == hyprland.get_focused_client():
                self.get_style_context().add_class("focused")
            else:
                self.get_style_context().remove_class("focused")

        def on_focused_workspace(*_):
            self.set_visible(c.get_workspace() == hyprland.get_focused_workspace())

        def on_client_moved(*_):
            self.set_visible(c.get_workspace() == hyprland.get_focused_workspace())

        def on_clicked(*_):
            if c != hyprland.get_focused_client():
                c.focus()

            if c.get_floating():
                hyprland.dispatch("alterzorder", f"top, {c.get_address()}")

        on_focused_c_id = hyprland.connect("notify::focused-client", on_focused_client)
        on_focused_ws_id = hyprland.connect("notify::focused-workspace", on_focused_workspace)
        on_c_moved_id = hyprland.connect("client-moved", on_client_moved)
        on_clicked_id = self.connect("clicked", on_clicked)

        def on_destroy(*_):
            hyprland.disconnect(on_focused_c_id)
            hyprland.disconnect(on_focused_ws_id)
            hyprland.disconnect(on_c_moved_id)
            self.disconnect(on_clicked_id)

        self.connect("destroy", on_destroy)
        self.get_style_context().add_class("client-button")
        self.get_style_context().add_class(c == hyprland.get_focused_client() and "focused" or "")
        self.set_visible(c.get_workspace() == hyprland.get_focused_workspace())

class ClientsWidget(Gtk.Box):
    def __init__(self):
        super().__init__(visible = True)
        self.get_style_context().add_class("clients-box")

        hyprland = AstalHyprland.get_default()

        def on_clients(*_):
            for child in self.get_children():
                child.destroy()

            for c in hyprland.get_clients():
                self.add(ClientButton(c))

        hyprland.connect("notify::clients", on_clients)

        for c in hyprland.get_clients():
            self.add(ClientButton(c))
