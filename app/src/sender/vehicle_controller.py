import time
from typing import Dict, Any

from piracer.vehicles import PiRacerStandard
from gamepads import ShanWanGamepad

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

BUS_NAME = 'org.piracer.VehicleController'
OBJECT_PATH = '/org/piracer/VehicleController'
INTERFACE = 'org.piracer.VehicleInterface'


class VehicleController:
    def __init__(self):
        self.piracer = PiRacerStandard()
        self.gamepad = ShanWanGamepad()
        self.gear = "N"

    def update_controls(self) -> Dict[str, Any]:
        gamepad_input = self.gamepad.read_data()

        a = gamepad_input.button_a  # Drive
        b = gamepad_input.button_b  # Park
        x = gamepad_input.button_x  # Neutral
        y = gamepad_input.button_y  # Reverse

        throttle_input = gamepad_input.analog_stick_right.y
        steering_input = -gamepad_input.analog_stick_left.x

        if self.gear == "D":
            throttle = max(0.0, throttle_input) * 0.5
        elif self.gear == "R":
            throttle = min(0.0, throttle_input) * 0.5
        else:
            throttle = 0.0

        steering = steering_input

        self.piracer.set_throttle_percent(throttle)
        self.piracer.set_steering_percent(steering)

        # Gear change handling
        previous_gear = self.gear
        if a:
            self.gear = "D"
        elif b:
            self.gear = "P"
        elif x:
            self.gear = "N"
        elif y:
            self.gear = "R"

        return {
            'throttle': throttle,
            'steering': steering,
            'gear': self.gear,
            'throttle_input': throttle_input,
            'steering_input': steering_input
        }

    def get_gear(self) -> str:
        return self.gear

    def cleanup(self):
        try:
            self.piracer.set_throttle_percent(0.0)
            self.piracer.set_steering_percent(0.0)
        except Exception:
            pass


class VehicleControllerService(dbus.service.Object):
    def __init__(self, bus, controller: VehicleController):
        super().__init__(bus, OBJECT_PATH)
        self.controller = controller
        self._last_gear = controller.get_gear()

    @dbus.service.method(INTERFACE, in_signature='', out_signature='s')
    def GetGear(self):
        return self.controller.get_gear()

    # Modified signal declaration: must specify signature='s' (string argument)
    @dbus.service.signal(INTERFACE, signature='s')
    def gearChanged(self, gear):
        pass

    def emit_gear_changed_if_needed(self):
        current_gear = self.controller.get_gear()
        if current_gear != self._last_gear:
            self.gearChanged(current_gear)  # Emit signal with argument
            self._last_gear = current_gear


if __name__ == '__main__':
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(BUS_NAME, bus)

    controller = VehicleController()
    service = VehicleControllerService(bus, controller)

    loop = GLib.MainLoop()

    try:
        while True:
            controller.update_controls()
            service.emit_gear_changed_if_needed()  # Emit signal when gear changes
            while loop.get_context().pending():
                loop.get_context().iteration(False)
            time.sleep(0.02)
    except KeyboardInterrupt:
        pass
    finally:
        controller.cleanup()
