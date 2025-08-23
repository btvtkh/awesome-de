import time
from datetime import datetime
from gi.repository import GLib, Gtk

def calc_interval(interval):
    return interval - int(time.time()) % interval

class DateTimeWidget(Gtk.Box):
    def __init__(self):
        super().__init__(visible = True)

        time_label = Gtk.Label(visible = True)
        date_label = Gtk.Label(visible = True)

        def timeout_callback():
            date_label.set_label(datetime.now().strftime("%d %b, %a"))
            time_label.set_label(datetime.now().strftime("%H:%M"))
            GLib.timeout_add_seconds(
                priority = GLib.PRIORITY_DEFAULT,
                interval = calc_interval(60),
                function = timeout_callback
            )
            return GLib.SOURCE_REMOVE

        self.get_style_context().add_class("date-time-box")

        self.add(date_label)
        self.add(Gtk.Separator(visible = True))
        self.add(time_label)

        timeout_callback()
