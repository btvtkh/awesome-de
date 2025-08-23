from datetime import datetime
from gi.repository import Gtk, Pango

UrgencyMap = {
    "0": "low",
    "1": "normal",
    "2": "critical"
}

class ActionButton(Gtk.Button):
    def __init__(self, n, action):
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

        def on_clicked(*_):
            n.invoke(action.id)

        on_clicked_id = self.connect("clicked", on_clicked)

        def on_destroy(*_):
            self.disconnect(on_clicked_id)

        self.connect("destroy", on_destroy)

        self.get_style_context().add_class("action-button")

class NotificationWidget(Gtk.Box):
    def __init__(self, n):
        super().__init__(
            orientation = Gtk.Orientation.VERTICAL
        )

        app_name_label = Gtk.Label(
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.END,
            label = n.get_app_name() or "Unknown"
        )

        time_label = Gtk.Label(
            hexpand = True,
            halign = Gtk.Align.END,
            label = datetime.fromtimestamp(n.get_time()).strftime("%H:%M")
        )

        close_button = Gtk.Button(
            child = Gtk.Image(
                icon_size = Gtk.IconSize.BUTTON,
                icon_name = "window-close-symbolic"
            )
        )

        summary_label = Gtk.Label(
            halign = Gtk.Align.START,
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 25,
            label = n.get_summary()
        )

        body_label = Gtk.Label(
            use_markup = True,
            halign = Gtk.Align.START,
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 30,
            label = n.get_body()
        )

        header_box = Gtk.Box()
        body_box = Gtk.Box(orientation = Gtk.Orientation.VERTICAL)
        content_box = Gtk.Box()
        actions_box = Gtk.Box()

        def on_close_clicked(*_):
            n.dismiss()

        on_close_clicked_id = close_button.connect("clicked", on_close_clicked)

        def on_destroy(*_):
            close_button.disconnect(on_close_clicked_id)

        self.connect("destroy", on_destroy)

        self.get_style_context().add_class("notification-box")
        self.get_style_context().add_class(UrgencyMap[str(n.get_urgency())])
        app_name_label.get_style_context().add_class("app-name-label")
        time_label.get_style_context().add_class("time-label")
        close_button.get_style_context().add_class("close-button")
        header_box.get_style_context().add_class("header-box")
        summary_label.get_style_context().add_class("summary-label")
        body_label.get_style_context().add_class("body-label")
        content_box.get_style_context().add_class("content-box")
        actions_box.get_style_context().add_class("actions-box")

        header_box.add(app_name_label)
        header_box.add(time_label)
        header_box.add(close_button)
        body_box.add(summary_label)
        body_box.add(body_label)
        content_box.add(body_box)
        self.add(header_box)
        self.add(Gtk.Separator())
        self.add(content_box)
        if n.get_actions():
            for action in n.get_actions():
                actions_box.add(ActionButton(n, action))
            self.add(actions_box)
