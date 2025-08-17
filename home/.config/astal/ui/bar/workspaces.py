from gi.repository import Gtk, AstalHyprland as Hyprland

class WorkspaceButton(Gtk.Button):
    def __init__(self, ws):

        hyprland = Hyprland.get_default()

        def on_focused_ws(*_):
            if ws == hyprland.get_focused_workspace():
                self.get_style_context().add_class("focused")
            else:
                self.get_style_context().remove_class("focused")

        def on_clicked(*_):
            if ws != hyprland.get_focused_workspace():
                ws.focus()

        super().__init__(
            visible = True,
            child = Gtk.Label(
                visible = True,
                label = ws.get_name()
            )
        )

        on_focused_ws_id = hyprland.connect("notify::focused-workspace", on_focused_ws)
        on_clicked_id = self.connect("clicked", on_clicked)

        def on_destroy(*_):
            hyprland.disconnect(on_focused_ws_id)
            self.disconnect(on_clicked_id)

        self.connect("destroy", on_destroy)
        self.get_style_context().add_class("workspace-button")
        self.get_style_context().add_class(ws == hyprland.get_focused_workspace() and "focused" or "")

class WorkspacesWidget(Gtk.Box):
    def __init__(self):

        hyprland = Hyprland.get_default()

        def on_workspaces(*_):
            for child in self.get_children():
                child.destroy()

            wss = hyprland.get_workspaces()
            wss.sort(key = lambda x: x.get_id())
            for ws in wss:
                if not (ws.get_id() >= -99 and ws.get_id() <= -2):
                    self.add(WorkspaceButton(ws))

        super().__init__()
        hyprland.connect("notify::workspaces", on_workspaces)
        self.get_style_context().add_class("workspaces-box")

        wss = hyprland.get_workspaces()
        wss.sort(key = lambda x: x.get_id())
        for ws in wss:
            if not (ws.get_id() >= -99 and ws.get_id() <= -2):
                self.add(WorkspaceButton(ws))
