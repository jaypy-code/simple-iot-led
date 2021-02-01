#include <WiFiManager.h>
#include <PubSubClient.h>
#include <ESP8266WiFi.h>

// LED confing
int led_status = 1;
unsigned short int led_status_timeout = 5000;

// wifi manager config
WiFiManager wm;
const char* access_point_name = "ESP8266_ACCESS_POINT";

// mqtt config
const char* mqtt_subscribe = "led/set";
const char* mqtt_server = "s1.rayconnect.ir";
const char* mqtt_username = "rayconnect:jaypy_esp_led";
const char* mqtt_password = "1234";
const char* mqtt_clientId = "ESP_LED_CLIENT";
unsigned short int mqtt_timeout = 5000;
unsigned long lastMessage = 0;
WiFiClient wifiClient;
PubSubClient mqtt(wifiClient);

// 1 is off - 0 is on
void setLedStatus(int set_led_status)
{
  led_status = set_led_status;
  digitalWrite(LED_BUILTIN, led_status);
  mqtt.publish("led/status", String(led_status).c_str());
  Serial.print("led status: ");
  Serial.println(String(led_status).c_str());
}

// Try connect to mqtt server
void reconnect()
{
  // A loop while esp connect to mqtt server
  while (mqtt.connected() == false)
  {
    Serial.println("Connecting to mqtt server ...");
    if (mqtt.connect(mqtt_clientId, mqtt_username, mqtt_password))
    {
      Serial.println("Connected to mqtt server!");
      mqtt.subscribe(mqtt_subscribe); // subscribe to led set topic
      setLedStatus(1);
    }
    else
    {
      Serial.print("Failed to connect, tring again in ");
      Serial.print(mqtt_timeout / 1000);
      Serial.println(" second(s).");
      delay(mqtt_timeout);
    }
  }
}

// mqtt subscribe
void callback(char *topic, byte *payload, unsigned int length)
{
  if (String(topic) == "led/set")
  {
    if ((char)payload[0] == '1')
      setLedStatus(1); // off
    else
      setLedStatus(0); // on
  }
}

void setup()
{
  // put your setup code here, to run once:
  pinMode(LED_BUILTIN, OUTPUT); // set dgital pin LED as an output
  WiFi.mode(WIFI_STA);          // set wifi mode to station and access point
  Serial.begin(115200);         // set esp serial speed

  // wm.resetSettings(); // reset saved wifis

  wm.setConfigPortalBlocking(false);

  // try to connect saved wifi else create an access point
  if (wm.autoConnect(access_point_name))
  {
    Serial.println("Connected successfully!");
  }
  else
  {
    Serial.println("Access point mode enabled!");
  }

  // check wifi status is connected
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(1000);
  }

  mqtt.setServer(mqtt_server, 1883);
  mqtt.setCallback(callback);
}

void loop()
{
  // put your main code here, to run repeatedly:
  wm.process();

  if (mqtt.connected() == false)
  {
    reconnect();
  }
  mqtt.loop();

  unsigned long now = millis();
  if (now - lastMessage > led_status_timeout)
  {
    lastMessage = now;
    mqtt.publish("led/status", String(led_status).c_str());
  }
}
