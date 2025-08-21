from datetime import datetime as DateTime
from gi.repository import Gtk, Pango

UrgencyMap = {
    "0": "low",
    "1": "normal",
    "2": "critical"
}

class ActionButton(Gtk.Button):
    def __init__(self, n, action):

        def on_clicked(*_):
            n.invoke(action.id)

        super().__init__(
            hexpand = True,
            child = Gtk.Label(
                hexpand = True,
                halign = Gtk.Align.CENTER,
                ellipsize = Pango.EllipsizeMode.END,
                max_width_chars = 10,
                label = action.label
            )
        )

        self.get_style_context().add_class("action-button")

        on_clicked_id = self.connect("clicked", on_clicked)

        def on_destroy(*_):
            self.disconnect(on_clicked_id)

        self.connect("destroy", on_destroy)

class NotificationWidget(Gtk.Box):
    def __init__(self, n):

        def on_close_clicked(*_):
            n.dismiss()

        app_name_label = Gtk.Label(
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.END,
            label = n.get_app_name() or "Unknown"
        )
        app_name_label.get_style_context().add_class("app-name-label")

        time_label = Gtk.Label(
            hexpand = True,
            halign = Gtk.Align.END,
            label = DateTime.fromtimestamp(n.get_time()).strftime("%H:%M")
        )
        time_label.get_style_context().add_class("time-label")

        close_button = Gtk.Button(
            child = Gtk.Image(
                icon_size = Gtk.IconSize.BUTTON,
                icon_name = "window-close-symbolic"
            )
        )
        close_button.get_style_context().add_class("close-button")

        summary_label = Gtk.Label(
            halign = Gtk.Align.START,
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 25,
            label = n.get_summary()
        )
        summary_label.get_style_context().add_class("summary-label")

        body_label = Gtk.Label(
            use_markup = True,
            halign = Gtk.Align.START,
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 30,
            label = n.get_body()
        )
        body_label.get_style_context().add_class("body-label")

        header_box = Gtk.Box()
        header_box.get_style_context().add_class("header-box")
        header_box.add(app_name_label)
        header_box.add(time_label)
        header_box.add(close_button)

        body_box = Gtk.Box(
            orientation = Gtk.Orientation.VERTICAL
        )
        body_box.add(summary_label)
        body_box.add(body_label)

        content_box = Gtk.Box()
        content_box.get_style_context().add_class("content-box")
        content_box.add(body_box)

        super().__init__(
            orientation = Gtk.Orientation.VERTICAL
        )

        self.get_style_context().add_class("notification-box")
        self.get_style_context().add_class(UrgencyMap[str(n.get_urgency())])
        self.add(header_box)
        self.add(Gtk.Separator())
        self.add(content_box)

        if n.get_actions():
            actions_box = Gtk.Box()
            actions_box.get_style_context().add_class("actions-box")

            for action in n.get_actions():
                actions_box.add(ActionButton(n, action))

            self.add(actions_box)

        on_close_clicked_id = close_button.connect("clicked", on_close_clicked)

        def on_destroy(*_):
            close_button.disconnect(on_close_clicked_id)

        self.connect("destroy", on_destroy)


