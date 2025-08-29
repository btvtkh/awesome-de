from gi.repository import Gtk, GtkLayerShell
from .workspaces import WorkspacesWidget
from .clients import ClientsWidget
from .date_time import DateTimeWidget
from .tray import TrayWidget
from .kb_layout import KbLayoutWidget

class Bar(Gtk.Window):
    def __init__(self, monitor):
        super().__init__(
            name = "Bar"
        )

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "Astal-Bar")
        GtkLayerShell.set_monitor(self, monitor)
        GtkLayerShell.auto_exclusive_zone_enable(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)

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
        self.show()
