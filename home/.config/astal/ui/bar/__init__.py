from gi.repository import Gtk, Astal
from .workspaces import WorkspacesWidget
from .clients import ClientsWidget
from .date_time import DateTimeWidget
from .tray import TrayWidget
from .kb_layout import KbLayoutWidget

class Bar(Astal.Window):
    def __init__(self, monitor):
        super().__init__(
            gdkmonitor = monitor,
            layer = Astal.Layer.TOP,
            anchor = Astal.WindowAnchor.BOTTOM
                | Astal.WindowAnchor.LEFT
                | Astal.WindowAnchor.RIGHT,
            exclusivity = Astal.Exclusivity.EXCLUSIVE,
            namespace = "Astal-Bar",
            name = "Bar",
            visible = True
        )

        left_box = Gtk.Box(
            hexpand = True,
            visible = True
        )

        right_box = Gtk.Box(
            halign = Gtk.Align.END,
            visible = True
        )

        main_box = Gtk.Box(
            visible = True
        )

        self.get_style_context().add_class("bar-window")
        main_box.get_style_context().add_class("bar-box")

        left_box.add(WorkspacesWidget())
        left_box.add(ClientsWidget())
        right_box.add(TrayWidget())
        right_box.add(KbLayoutWidget())
        right_box.add(DateTimeWidget())
        main_box.add(left_box)
        main_box.add(right_box)
        self.add(main_box)
