import gi
gi.require_version("GLib", "2.0")
gi.require_version("Gio", "2.0")
gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("Pango", "1.0")
gi.require_version('GtkLayerShell', '0.1')
gi.require_version("AstalIO", "0.1")
gi.require_version("Astal", "3.0")
gi.require_version("AstalHyprland", "0.1")
gi.require_version("AstalNotifd", "0.1")
gi.require_version("AstalTray", "0.1")

import sys
from gi.repository import AstalIO
from app import App

app = App(instance_name = "astal-py")

if __name__ == "__main__":
    try:
        app.acquire_socket()
        app.run(None)
    except Exception:
        print(AstalIO.send_request(
            "astal-py",
            "".join(sys.argv[1:])
        ))
