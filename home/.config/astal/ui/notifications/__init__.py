from gi.repository import GLib, Gtk, Astal, AstalNotifd as Notifd
from .notification import NotificationWidget

class NotificationPopup(Gtk.Box):
    def __init__(self, window, n):

        outer = Gtk.Revealer(
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        )

        inner = Gtk.Revealer(
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        )

        def on_resolved(*_):
            def on_outer_timeout_end():
                self.destroy()
                if window.get_visible() and not window.get_child().get_children():
                    window.hide()
                return GLib.SOURCE_REMOVE

            def on_inner_timeout_end():
                outer.set_reveal_child(False)
                GLib.timeout_add(
                    priority = GLib.PRIORITY_DEFAULT,
                    interval = outer.get_transition_duration(),
                    function = on_outer_timeout_end
                )
                return GLib.SOURCE_REMOVE

            inner.set_reveal_child(False)
            GLib.timeout_add(
                priority = GLib.PRIORITY_DEFAULT,
                interval = inner.get_transition_duration(),
                function = on_inner_timeout_end
            )


        super().__init__(
            halign = Gtk.Align.END,
        )

        on_resolved_id = n.connect("resolved", on_resolved)

        inner.add(NotificationWidget(n))
        outer.add(inner)
        self.add(outer)

        def on_destroy(*_):
            n.disconnect(on_resolved_id)

        self.connect("destroy", on_destroy)

        def on_display_timeout_end():
            #on_resolved()
            n.dismiss()
            return GLib.SOURCE_REMOVE

        GLib.timeout_add_seconds(
            priority = GLib.PRIORITY_DEFAULT,
            interval = 5,
            function = on_display_timeout_end
        )

class Notifications(Astal.Window):
    def __init__(self):

        notifd = Notifd.get_default()

        notifications_box = Gtk.Box(
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START,
        )

        def on_notified(x, id, replaced):
            n = notifd.get_notification(id)
            popup = NotificationPopup(self, n)
            outer = popup.get_children()[0]
            inner = outer.get_child()

            def on_outer_timeout_end():
                inner.set_reveal_child(True)
                return GLib.SOURCE_REMOVE

            if not self.get_visible():
                self.show()

            notifications_box.pack_end(popup, False, False, 0)
            popup.show_all()
            outer.set_reveal_child(True)

            GLib.timeout_add(
                priority = GLib.PRIORITY_DEFAULT,
                interval = outer.get_transition_duration(),
                function = on_outer_timeout_end
            )

        super().__init__(
            layer = Astal.Layer.TOP,
            anchor = Astal.WindowAnchor.TOP
                | Astal.WindowAnchor.RIGHT,
            exclusivity = Astal.Exclusivity.EXCLUSIVE,
            namespace = "Astal-Notifications",
            name = "Notifications"
        )

        self.get_style_context().add_class("notifications-window")
        self.add(notifications_box)

        notifd.connect("notified", on_notified)

        ns = notifd.get_notifications()
        ns.sort(key = lambda x: x.get_id())
        for n in ns:
            popup = NotificationPopup(self, n)
            outer = popup.get_children()[0]
            inner = outer.get_child()
            notifications_box.pack_end(popup, False, False, 0)
            inner.set_reveal_child(True)
            outer.set_reveal_child(True)

        self.show_all()
