from gi.repository import Gtk, Astal
from .workspaces import WorkspacesWidget
from .clients import ClientsWidget

class Bar(Astal.Window):
    def __init__(self, monitor):

        left_box = Gtk.Box()
        left_box.add(WorkspacesWidget())
        left_box.add(ClientsWidget())

        right_box = Gtk.Box()

        main_box = Gtk.Box()
        main_box.get_style_context().add_class("bar-box")
        main_box.add(left_box)
        main_box.add(right_box)

        super().__init__(
            gdkmonitor = monitor,
            layer = Astal.Layer.TOP,
            anchor = Astal.WindowAnchor.BOTTOM
                | Astal.WindowAnchor.LEFT
                | Astal.WindowAnchor.RIGHT,
            exclusivity = Astal.Exclusivity.EXCLUSIVE,
            namespace = "Astal-Bar",
            name = "Bar"
        )

        self.get_style_context().add_class("bar-window")
        self.add(main_box)
        self.show_all()
