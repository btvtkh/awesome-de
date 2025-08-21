import gi
gi.require_version("GLib", "2.0")
gi.require_version("Gio", "2.0")
gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("Pango", "1.0")
gi.require_version("AstalIO", "0.1")
gi.require_version("Astal", "3.0")
gi.require_version("AstalHyprland", "0.1")
gi.require_version("AstalNotifd", "0.1")
gi.require_version("AstalApps", "0.1")

import sys
import subprocess
from pathlib import Path
from gi.repository import AstalIO, Astal
from ui.bar import Bar
from ui.notifications import Notifications
from ui.launcher import Launcher

scss = str(Path(__file__).parent.resolve() / "index.scss")
css = "/tmp/style.css"

class App(Astal.Application):
    def do_activate(self):
        self.hold()
        subprocess.run(["sass", scss, css])
        self.apply_css(css, True)

        for mon in self.get_monitors():
            self.add_window(Bar(mon))

        self.add_window(Notifications())
        self.add_window(Launcher())

instance_name = "astal-py"
app = App(instance_name = instance_name)

if __name__ == "__main__":
    try:
        app.acquire_socket()
        app.run(None)
    except Exception:
        print(
            AstalIO.send_request(
                instance_name,
                "".join(sys.argv[1:])
            )
        )
