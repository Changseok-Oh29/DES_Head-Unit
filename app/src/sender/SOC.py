import time
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
from piracer.vehicles import PiRacerStandard

# Unified naming according to D-Bus rules
BUS_NAME = 'org.piracer.Battery'
OBJECT_PATH = '/org/piracer/Battery'
INTERFACE = 'org.piracer.Battery'

class BatteryMonitor:
    def __init__(self):
        self.piracer = PiRacerStandard()
        self.alpha = 0.1
        initial_voltage = self.piracer.get_battery_voltage()
        self.voltage_smoothed = initial_voltage

    def get_voltage(self) -> float:
        v = self.piracer.get_battery_voltage()
        self.voltage_smoothed = self.alpha * v + (1 - self.alpha) * self.voltage_smoothed
        return self.voltage_smoothed

    def get_current(self) -> float:
        return self.piracer.get_battery_current()


class BatteryService(dbus.service.Object):
    def __init__(self, bus, monitor: BatteryMonitor):
        super().__init__(bus, OBJECT_PATH)
        self.monitor = monitor
        self.was_charging = self.monitor.get_current() > 0.1

    # Added: Method for C++ client to request initial values
    # Returns a tuple (percentage, current)
    @dbus.service.method(INTERFACE, in_signature='', out_signature='(id)')
    def GetInitialStatus(self):
        voltage = self.monitor.get_voltage()
        percentage = self.get_percentage_from_voltage(voltage)
        current = self.monitor.get_current()
        return percentage, current

    @dbus.service.signal(INTERFACE, signature='d')
    def chargingStatusChanged(self, current):
        pass

    @dbus.service.signal(INTERFACE, signature='i')
    def percentageChanged(self, percentage):
        pass

    def get_percentage_from_voltage(self, voltage):
        # Based on 3-cell (3S) LiPo battery voltage
        MIN_VOLTAGE = 9.0
        MAX_VOLTAGE = 12.6
        percentage = ((voltage - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE)) * 100.0
        return max(0, min(100, int(percentage)))

    def check_charging_status(self):
        current = self.monitor.get_current()
        is_charging = current > 0.1

        if is_charging != self.was_charging:
            self.chargingStatusChanged(current)
            self.was_charging = is_charging

    def emit_percentage(self):
        voltage = self.monitor.get_voltage()
        percentage = self.get_percentage_from_voltage(voltage)
        self.percentageChanged(percentage)


if __name__ == '__main__':
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(BUS_NAME, bus)

    monitor = BatteryMonitor()
    service = BatteryService(bus, monitor)

    loop = GLib.MainLoop()
    
    last_percentage_emit_time = time.time()

    try:
        while True:
            service.check_charging_status()
            current_time = time.time()
            if current_time - last_percentage_emit_time >= 120:
                service.emit_percentage()
                last_percentage_emit_time = current_time
            while loop.get_context().pending():
                loop.get_context().iteration(False)
            time.sleep(0.5)
    except KeyboardInterrupt:
        pass
