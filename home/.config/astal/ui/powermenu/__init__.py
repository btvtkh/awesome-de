from gi.repository import Gdk, Gtk, Astal, AstalHyprland

class Powermenu(Astal.Window):
    def __init__(self):
        super().__init__(
            layer = Astal.Layer.TOP,
            anchor = Astal.WindowAnchor.BOTTOM
                | Astal.WindowAnchor.TOP
                | Astal.WindowAnchor.LEFT
                | Astal.WindowAnchor.RIGHT,
            keymode = Astal.Keymode.ON_DEMAND,
            namespace = "Astal-Powermenu",
            name = "Powermenu",
            visible = False
        )

        hyprland = AstalHyprland.get_default()

        outside_hbox = Gtk.Box(visible = True)

        outside_vbox = Gtk.Box(
            visible = True,
            hexpand = False,
            orientation = Gtk.Orientation.VERTICAL
        )

        left_eventbox = Gtk.EventBox(hexpand = True, visible = True)
        right_eventbox = Gtk.EventBox(hexpand = True, visible = True)
        top_eventbox = Gtk.EventBox(vexpand = True, visible = True)
        bottom_eventbox = Gtk.EventBox(vexpand = True, visible = True)

        main_box = Gtk.Box(visible = True)

        power_button = Gtk.Button(
            visible = True,
            child = Gtk.Image(
                visible = True,
                icon_name = "system-shutdown-symbolic",
                pixel_size = 32
            )
        )

        reboot_button = Gtk.Button(
            visible = True,
            child = Gtk.Image(
                visible = True,
                icon_name = "system-reboot-symbolic",
                pixel_size = 32
            )
        )

        exit_button = Gtk.Button(
            visible = True,
            child = Gtk.Image(
                visible = True,
                icon_name = "system-log-out-symbolic",
                pixel_size = 32
            )
        )

        def on_window_key_press(self, event):
            if event.keyval == Gdk.KEY_Escape:
                self.hide()

        def on_evetbox_click(*_):
            self.hide()

        def on_visible(*_):
            if self.get_visible():
                main_box.get_children()[0].grab_focus()

        def on_power_button_clicked(*_):
            self.hide()
            hyprland.dispatch("exec", "poweroff")

        def on_power_button_key_press(x, event):
             if event.keyval == Gdk.KEY_Return:
                on_power_button_clicked()

        def on_reboot_button_clicked(*_):
            self.hide()
            hyprland.dispatch("exec", "reboot")

        def on_reboot_button_key_press(x, event):
             if event.keyval == Gdk.KEY_Return:
                on_reboot_button_clicked()

        def on_exit_button_clicked(*_):
            self.hide()
            hyprland.dispatch("exit", "")

        def on_exit_button_key_press(x, event):
             if event.keyval == Gdk.KEY_Return:
                on_exit_button_clicked()

        power_button.connect("clicked", on_power_button_clicked)
        power_button.connect("key-press-event", on_power_button_key_press)
        reboot_button.connect("clicked", on_reboot_button_clicked)
        reboot_button.connect("key-press-event", on_reboot_button_key_press)
        exit_button.connect("clicked", on_exit_button_clicked)
        exit_button.connect("key-press-event", on_exit_button_key_press)
        self.connect("key-press-event", on_window_key_press)
        self.connect("notify::visible", on_visible)
        for w in [left_eventbox, right_eventbox, top_eventbox, bottom_eventbox]:
            w.connect("button-press-event", on_evetbox_click)

        self.get_style_context().add_class("powermenu-window")
        main_box.get_style_context().add_class("powermenu-box")

        main_box.add(power_button)
        main_box.add(reboot_button)
        main_box.add(exit_button)
        outside_vbox.add(top_eventbox)
        outside_vbox.add(main_box)
        outside_vbox.add(bottom_eventbox)
        outside_hbox.add(left_eventbox)
        outside_hbox.add(outside_vbox)
        outside_hbox.add(right_eventbox)
        self.add(outside_hbox)

