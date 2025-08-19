import time as Time
from datetime import datetime as DateTime
from gi.repository import Gtk, AstalIO

def calc_timeout(real_timeout):
    return real_timeout - int(Time.time()) % real_timeout

class DateTimeWidget(Gtk.Box):
    def __init__(self):

        time_label = Gtk.Label()
        date_label = Gtk.Label()

        def timeout_callback():
            date_label.set_label(DateTime.now().strftime("%d %b, %a"))
            time_label.set_label(DateTime.now().strftime("%H:%M"))
            AstalIO.Time.timeout(calc_timeout(60)*1000, timeout_callback)

        super().__init__()
        self.get_style_context().add_class("date-time-box")

        self.add(date_label)
        self.add(Gtk.Separator())
        self.add(time_label)

        timeout_callback()
