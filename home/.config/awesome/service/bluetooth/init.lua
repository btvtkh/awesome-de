local GLib = require("lgi").require("GLib")
local dbus_proxy = require("lib.dbus_proxy")
local gobject = require("gears.object")
local gtable = require("gears.table")

local adapter = {}
local device = {}

function adapter:get_powered()
	if self._private.properties_proxy.interface
	and self._private.properties_proxy.Get then
		return self._private.properties_proxy:Get(
			self._private.adapter_proxy.interface,
			"Powered"
		)
	end
end

function adapter:get_discovering()
	if self._private.adapter_proxy.interface
	and self._private.properties_proxy.Get then
		return self._private.properties_proxy:Get(
			self._private.adapter_proxy.interface,
			"Discovering"
		)
	end
end

function adapter:get_devices()
	return self.devices
end

function adapter:get_device(path)
	return self.devices[path]
end

function adapter:set_powered(state)
	if self._private.adapter_proxy.interface
	and self._private.adapter_proxy.SetAsync then
		self._private.adapter_proxy:SetAsync(
			nil,
			{},
			self._private.adapter_proxy.interface,
			"Powered",
			GLib.Variant("b", state)
		)

		self._private.adapter_proxy.Powered = {
			signature = "b",
			value = state
		}
	end
end

function adapter:start_discovery()
	if self._private.adapter_proxy.StartDiscoveryAsync then
		if self:get_discovering() ~= true then
			self._private.adapter_proxy:StartDiscoveryAsync(nil, {})
		end
	end
end

function adapter:stop_discovery()
	if self._private.adapter_proxy.StopDiscoveryAsync then
		if self:get_discovering() == true then
			self._private.adapter_proxy:StopDiscoveryAsync(nil, {})
		end
	end
end

function device:get_connected()
	return self._private.properties_proxy:Get(
		self._private.device_proxy.interface,
		"Connected"
	)
end

function device:get_paired()
	return self._private.properties_proxy:Get(
		self._private.device_proxy.interface,
		"Paired"
	)
end

function device:get_trusted()
	return self._private.properties_proxy:Get(
		self._private.device_proxy.interface,
		"Trusted"
	)
end

function device:get_name()
	return self._private.properties_proxy:Get(
		self._private.device_proxy.interface,
		"Name"
	)
end

function device:get_icon()
	return self._private.properties_proxy:Get(
		self._private.device_proxy.interface,
		"Icon"
	)
end

function device:get_address()
	return self._private.properties_proxy:Get(
		self._private.device_proxy.interface,
		"Address"
	)
end

function device:get_percentage()
	return self._private.properties_proxy:Get(
		self._private.battery_proxy.interface,
		"Percentage"
	)
end

function device:get_path()
	return self._private.device_proxy.object_path
end

function device:connect()
	if self:get_connected() ~= true then
		self._private.device_proxy:ConnectAsync(nil, {})
	end
end

function device:disconnect()
	if self:get_connected() == true then
		self._private.device_proxy:DisconnectAsync(nil, {})
	end
end

function device:pair()
	if self:get_paired() ~= true then
		self._private.device_proxy:PairAsync(nil, {})
	end
end

function device:cancel_pairing()
	if self:get_paired() == true then
		self._private.device_proxy:CancelPairingAsync(nil, {})
	end
end

function device:set_trusted(trusted)
	self._private.device_proxy:SetAsync(
		nil,
		{},
		self._private.device_proxy.interface,
		"Trusted",
		GLib.Variant("b", trusted)
	)
	self._private.device_proxy.Trusted = {
		signature = "b",
		value = trusted
	}
end

local function create_device_object(path)
	if not path or path == "/" then return end

	local ret = gobject {}
	gtable.crush(ret, device, true)
	ret._private = {}

	ret._private.device_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		path = path,
		interface = "org.bluez.Device1"
	}

	ret._private.battery_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		path = path,
		interface = "org.bluez.Battery1"
	}

	ret._private.properties_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		path = path,
		interface = "org.freedesktop.DBus.Properties"
	}

	ret._private.properties_proxy:connect_signal("PropertiesChanged", function(_, _, props)
		if props.Connected ~= nil then
			ret:emit_signal("property::connected", props.Connected)
		end
		if props.Paired ~= nil then
			ret:emit_signal("property::paired", props.Paired)
		end
		if props.Trusted ~= nil then
			ret:emit_signal("property::trusted", props.Trusted)
		end
		if props.Percentage ~= nil then
			ret:emit_signal("property::percentage", props.Percentage)
		end
	end)

	return ret
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, adapter, true)
	ret._private = {}

	ret._private.object_manager_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		path = "/",
		interface = "org.freedesktop.DBus.ObjectManager"
	}

	ret._private.adapter_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		path = "/org/bluez/hci0",
		interface = "org.bluez.Adapter1"
	}

	ret._private.properties_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		path = "/org/bluez/hci0",
		interface = "org.freedesktop.DBus.Properties"
	}

	ret._private.properties_proxy:connect_signal("PropertiesChanged", function(_, _, props)
		if props.Powered ~= nil then
			ret:emit_signal("property::powered", props.Powered)
		end
		if props.Discovering ~= nil then
			ret:emit_signal("property::discovering", props.Discovering)
		end
	end)

	ret.devices = {}
	ret._private.object_manager_proxy:connect_signal("InterfacesAdded", function(_, path)
		if path:match("^/org/bluez/hci0/dev_%w%w_%w%w_%w%w_%w%w_%w%w_%w%w$") then
			ret.devices[path] = create_device_object(path)
			ret:emit_signal("device-added", path, ret:get_device(path))
		end
	end)

	ret._private.object_manager_proxy:connect_signal("InterfacesRemoved", function(_, path)
		if path:match("^/org/bluez/hci0/dev_%w%w_%w%w_%w%w_%w%w_%w%w_%w%w$")then
			ret:emit_signal("device-removed", path, ret:get_device(path))
			ret.devices[path] = nil
		end
	end)

	if ret._private.object_manager_proxy.GetManagedObjects then
		local object_paths = ret._private.object_manager_proxy:GetManagedObjects()
		for path, _ in pairs(object_paths) do
			if path:match("^/org/bluez/hci0/dev_%w%w_%w%w_%w%w_%w%w_%w%w_%w%w$") then
				ret.devices[path] = create_device_object(path)
			end
		end
	end

	return ret
end

local instance = nil
local function get_default()
	if not instance then
		instance = new()
	end
	return instance
end

return { get_default = get_default }
