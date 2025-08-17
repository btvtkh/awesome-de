from gi.repository import Gtk, Astal, AstalIO, AstalNotifd as Notifd
from .notification import NotificationWidget

class NotificationPopup(Gtk.Box):
    def __init__(self, window, n):

        self._outer = Gtk.Revealer(
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        )

        self._inner = Gtk.Revealer(
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        )

        def on_resolved(*_):
            def close():
                self.destroy()
                if window.get_visible() and not window.get_child().get_children():
                    window.hide()

            def animate_outer():
                self._outer.set_reveal_child(False)
                AstalIO.Time.timeout(
                    self._outer.get_transition_duration(),
                    close
                )

            def animate_inner():
                self._inner.set_reveal_child(False)
                AstalIO.Time.timeout(
                    self._inner.get_transition_duration(),
                    animate_outer
                )

            animate_inner()

        super().__init__(
            halign = Gtk.Align.END,
        )

        on_resolved_id = n.connect("resolved", on_resolved)

        self._inner.add(NotificationWidget(n))
        self._outer.add(self._inner)
        self.add(self._outer)

        def on_destroy(*_):
            n.disconnect(on_resolved_id)

        self.connect("destroy", on_destroy)

        #AstalIO.Time.timeout(10000, n.dismiss)

class Notifications(Astal.Window):
    def __init__(self, monitor):

        notifications = Notifd.get_default()

        notifications_box = Gtk.Box(
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START,
        )

        def on_notified(x, id, replaced):
            n = notifications.get_notification(id)
            popup = NotificationPopup(self, n)

            def open():
                notifications_box.pack_end(popup, False, False, 0)
                self.show_all()

            def animate_inner():
                popup._inner.set_reveal_child(True)

            def animate_outer():
                open()
                popup._outer.set_reveal_child(True)
                AstalIO.Time.timeout(
                    popup._outer.get_transition_duration(),
                    animate_inner
                )

            animate_outer()

        super().__init__(
            visible = False,
            gdkmonitor = monitor,
            layer = Astal.Layer.TOP,
            anchor = Astal.WindowAnchor.TOP
                | Astal.WindowAnchor.RIGHT,
            exclusivity = Astal.Exclusivity.EXCLUSIVE,
            namespace = "Astal-Notifications",
            name = "Notifications"
        )

        self.get_style_context().add_class("notifications-window")
        self.add(notifications_box)

        notifications.connect("notified", on_notified)
