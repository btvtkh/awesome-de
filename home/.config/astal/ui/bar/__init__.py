from gi.repository import Gtk, Astal
from .workspaces import WorkspacesWidget
from .clients import ClientsWidget
from .date_time import DateTimeWidget

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
        self.get_style_context().add_class("bar-window")

        left_box = Gtk.Box(
            hexpand = True,
            visible = True
        )
        left_box.add(WorkspacesWidget())
        left_box.add(ClientsWidget())

        right_box = Gtk.Box(
            halign = Gtk.Align.END,
            visible = True
        )
        right_box.add(DateTimeWidget())

        main_box = Gtk.Box(visible = True)
        main_box.get_style_context().add_class("bar-box")
        main_box.add(left_box)
        main_box.add(right_box)
        self.add(main_box)
