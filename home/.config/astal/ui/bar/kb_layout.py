from gi.repository import Gtk, AstalHyprland

class KbLayoutWidget(Gtk.Box):
    def __init__(self):
        super().__init__(visible = True)

        hyprland = AstalHyprland.get_default()

        kb_label = Gtk.Label(
            visible = True,
            label = "En"
        )

        def on_keyboard_layout(x, kb, lt):
            kb_label.set_label(lt[:2])

        hyprland.connect("keyboard-layout", on_keyboard_layout)

        self.get_style_context().add_class("kb-layout-box")

        self.add(kb_label)
