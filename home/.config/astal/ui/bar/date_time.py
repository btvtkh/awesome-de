import time as Time
from datetime import datetime as DateTime
from gi.repository import GLib, Gtk

def calc_interval(interval):
    return interval - int(Time.time()) % interval

class DateTimeWidget(Gtk.Box):
    def __init__(self):

        time_label = Gtk.Label(visible = True)
        date_label = Gtk.Label(visible = True)

        super().__init__(visible = True)
        self.get_style_context().add_class("date-time-box")

        def timeout_callback():
            date_label.set_label(DateTime.now().strftime("%d %b, %a"))
            time_label.set_label(DateTime.now().strftime("%H:%M"))
            GLib.timeout_add_seconds(
                priority = GLib.PRIORITY_DEFAULT,
                interval = calc_interval(60),
                function = timeout_callback
            )
            return GLib.SOURCE_REMOVE

        self.add(date_label)
        self.add(Gtk.Separator(visible = True))
        self.add(time_label)
        timeout_callback()
