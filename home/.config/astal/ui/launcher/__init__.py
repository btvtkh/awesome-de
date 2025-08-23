import re
from gi.repository import Gio, Gdk, Gtk, Pango, Astal, AstalHyprland

def launch_app(app):
    desktop = Gio.DesktopAppInfo.new(Gio.AppInfo.get_id(app))
    term = desktop.get_string("Terminal") == "true" and Gio.AppInfo.get_default_for_uri_scheme('terminal') or False

    AstalHyprland.get_default().dispatch("exec", f"{
        term and
            f"{term.get_executable()} -e {app.get_executable()}"
        or
            re.search("^env", app.get_executable()) and
                re.sub("%a", "", app.get_commandline())
            or
                app.get_executable()
    }")

def filter_apps(apps, query):
    query = re.escape(query)
    filtered = []
    filtered_any = []

    for app in apps:
        if app.should_show():
            if re.search("^" + query, app.get_name().casefold()):
                filtered.append(app)
            elif re.search(query, app.get_name().casefold()):
                filtered_any.append(app)
            elif re.search(query, app.get_executable().casefold()):
                filtered_any.append(app)
            elif re.search(query, app.get_description().casefold()):
                filtered_any.append(app)

    filtered.sort(key = lambda app: app.get_name())
    filtered_any.sort(key = lambda app: app.get_name())
    filtered += filtered_any

    del query
    del apps
    del filtered_any
    return filtered

class AppButton(Gtk.Button):
    def __init__(self, window, app):
        super().__init__(
            child = Gtk.Box(
                orientation = Gtk.Orientation.VERTICAL
            )
        )

        name_label = Gtk.Label(
            halign = Gtk.Align.START,
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 45,
            label = app.get_name()
        )

        description_label = Gtk.Label(
            halign = Gtk.Align.START,
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 45,
            label = app.get_description()
        )

        def on_activate(*_):
            window.hide()
            launch_app(app)

        def on_clicked(*_):
            window.hide()
            launch_app(app)

        on_activate_id = self.connect("activate", on_activate)
        on_clicked_id = self.connect("clicked", on_clicked)

        def on_destroy(*_):
            self.disconnect(on_activate_id)
            self.disconnect(on_clicked_id)

        self.connect("destroy", on_destroy)

        name_label.get_style_context().add_class("name-label")
        description_label.get_style_context().add_class("description-label")

        self.get_style_context().add_class("app-button")
        self.get_child().add(name_label)
        self.get_child().add(description_label)

class Launcher(Astal.Window):
    def __init__(self):
        super().__init__(
            layer = Astal.Layer.TOP,
            anchor = Astal.WindowAnchor.BOTTOM
                | Astal.WindowAnchor.TOP
                | Astal.WindowAnchor.LEFT
                | Astal.WindowAnchor.RIGHT,
            keymode = Astal.Keymode.ON_DEMAND,
            namespace = "Astal-Launcher",
            name = "Launcher"
        )

        outside_hbox = Gtk.Box()

        outside_vbox = Gtk.Box(
            hexpand = False,
            orientation = Gtk.Orientation.VERTICAL
        )

        left_eventbox = Gtk.EventBox(hexpand = True)
        right_eventbox = Gtk.EventBox(hexpand = True)
        top_eventbox = Gtk.EventBox(vexpand = True)
        bottom_eventbox = Gtk.EventBox(vexpand = True)

        main_box = Gtk.Box(
            orientation = Gtk.Orientation.VERTICAL
        )

        apps_box = Gtk.Box(
            orientation = Gtk.Orientation.VERTICAL
        )

        apps_scroll = Gtk.ScrolledWindow(
            width_request = 400,
            height_request = 450,
            hexpand = False,
            vexpand = False
        )

        search_entry = Gtk.Entry(
            placeholder_text = "Search..."
        )

        def on_window_key_press(self, event):
            if event.keyval == Gdk.KEY_Escape:
                self.hide()

        def on_evetbox_click(*_):
            self.hide()

        def on_visible(*_):
            if apps_box.get_children():
                for child in apps_box.get_children():
                    child.destroy()

            if self.get_visible():
                search_entry.set_text("")
                search_entry.set_position(-1)
                search_entry.select_region(0, -1)
                search_entry.grab_focus()
                apps_scroll.get_vadjustment().set_value(
                    apps_scroll.get_vadjustment().get_lower()
                )

                if not apps_box.get_children():
                    for app in filter_apps(Gio.AppInfo.get_all(), ""):
                        apps_box.add(AppButton(self, app))

                self.show_all()

        def on_search_text(*_):
            if apps_box.get_children():
                for child in apps_box.get_children():
                    child.destroy()

            apps_list = filter_apps(Gio.AppInfo.get_all(), search_entry.get_text())

            if len(apps_list) > 0:
                for app in apps_list:
                    apps_box.add(AppButton(self, app))
            else:
                no_match_box = Gtk.Box(
                    halign = Gtk.Align.CENTER,
                    valign = Gtk.Align.CENTER,
                    hexpand = True,
                    vexpand = True
                )

                no_match_label = Gtk.Label(
                    label = "No match found"
                )

                no_match_label.get_style_context().add_class("no-match-label")
                no_match_box.add(no_match_label)
                apps_box.add(no_match_box)

            apps_box.show_all()
            del apps_list

        def on_search_activate(*_):
            if apps_box.get_children():
                if isinstance(apps_box.get_children()[0], Gtk.Button):
                    apps_box.get_children()[0].activate()

        search_entry.connect("activate", on_search_activate)
        search_entry.connect("notify::text", on_search_text)
        self.connect("key-press-event", on_window_key_press)
        self.connect("notify::visible", on_visible)
        for w in [left_eventbox, right_eventbox, top_eventbox, bottom_eventbox]:
            w.connect("button-press-event", on_evetbox_click)

        self.get_style_context().add_class("launcher-window")
        main_box.get_style_context().add_class("launcher-box")
        apps_scroll.get_style_context().add_class("apps-scroll")
        search_entry.get_style_context().add_class("search-entry")

        apps_scroll.add(apps_box)
        main_box.add(search_entry)
        main_box.add(apps_scroll)
        outside_vbox.add(top_eventbox)
        outside_vbox.add(main_box)
        outside_vbox.add(bottom_eventbox)
        outside_hbox.add(left_eventbox)
        outside_hbox.add(outside_vbox)
        outside_hbox.add(right_eventbox)
        self.add(outside_hbox)
