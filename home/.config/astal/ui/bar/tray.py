from gi.repository import Gtk, AstalTray

class TrayItem(Gtk.MenuButton):
    def __init__(self, item):
        super().__init__(
            visible = True,
            use_popover = False,
            height_request = 20,
            child = Gtk.Image(
                visible = True,
                pixel_size = 16
            )
        )

        def on_gicon(*_):
            self.get_child().set_from_gicon(item.get_gicon(), Gtk.IconSize.INVALID)

        def on_menu_model(*_):
            self.set_menu_model(item.get_menu_model())

        def on_action_group(*_):
            self.insert_action_group("dbusmenu", item.get_action_group())

        on_gicon_id = item.connect("notify::gicon", on_gicon)
        on_menu_model_id = item.connect("notify::menu-model", on_menu_model)
        on_action_group_id = item.connect("notify::action-group", on_action_group)

        def on_destroy(*_):
            item.disconnect(on_gicon_id)
            item.disconnect(on_menu_model_id)
            item.disconnect(on_action_group_id)

        self.connect("destroy", on_destroy)

        self.get_style_context().add_class("item-menu-button")

        self.get_child().set_from_gicon(item.get_gicon(), Gtk.IconSize.INVALID)
        self.set_menu_model(item.get_menu_model())
        self.insert_action_group("dbusmenu", item.get_action_group())

class TrayWidget(Gtk.Box):
    def __init__(self):
        super().__init__(visible = True)

        tray = AstalTray.get_default()
        items = {}

        items_box = Gtk.Box(
            visible = True
        )

        items_revealer = Gtk.Revealer(
            visible = True,
            reveal_child = False,
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        )

        reveal_button = Gtk.Button(
            visible = True,
            child = Gtk.Image(
                visible = True,
                icon_name = "pan-start-symbolic",
            )
        )

        def on_reveal_button_clicked(*_):
            items_revealer.set_reveal_child(not items_revealer.get_reveal_child())
            reveal_button.get_child().set_from_icon_name(
                items_revealer.get_reveal_child() and "pan-end-symbolic" or "pan-start-symbolic",
                Gtk.IconSize.BUTTON
            )

        def on_item_added(x, id):
            tray_item = TrayItem(tray.get_item(id))
            items[id] = tray_item
            items_box.add(tray_item)

        def on_item_removed(x, id):
            items[id].destroy()
            del items[id]

        reveal_button.connect("clicked", on_reveal_button_clicked)
        tray.connect("item-removed", on_item_removed)
        tray.connect("item-added", on_item_added)

        self.get_style_context().add_class("tray-box")
        reveal_button.get_style_context().add_class("reveal-button")

        items_revealer.add(items_box)
        self.add(reveal_button)
        self.add(items_revealer)
