# Simple iot led
This is a simple iot project with esp8266 just for learning iot with this module. We have esp codes and a flutter application to turn it on and off with mqtt protocol.

# esp codes
I connect to wifi then connect to mqtt. When module connect to mqtt, it sends (publish) led status each time you'll set but as default it's 3000ms. It listen (subscribe) to *led/set* topic to set led status; 0 is on and 1 is off.

# flutter app
It connect to mqtt server and listen (subscribe) to *led/status* to get led status and when you tap on on/off button, it sends (publish) new status to led and led will turn on or off.
