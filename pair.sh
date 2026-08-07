#!/bin/bash

bluetoothctl remove 2C:32:6A:D6:65:79; bluetoothctl --timeout 20 scan on;
  bluetoothctl pair 2C:32:6A:D6:65:79 && bluetoothctl trust
  2C:32:6A:D6:65:79 && bluetoothctl connect 2C:32:6A:D6:65:7
