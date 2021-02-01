import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(
    MaterialApp(
      home: App(),
    ),
  );
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  int status = 1;
  bool connected = false;
  MqttServerClient client;
  // ignore: non_constant_identifier_names
  String mqtt_server = "s1.rayconnect.ir";
  // ignore: non_constant_identifier_names
  String mqtt_username = "rayconnect:jaypy_username";
  // ignore: non_constant_identifier_names
  String mqtt_password = "1234";

  @override
  void initState() {
    super.initState();
    this.connect();
  }

  Future<void> connect() async {
    setState(() {
      client = MqttServerClient.withPort(this.mqtt_server, "local", 1883);
      connected = false;
    });
    this.client.logging(on: false);
    this.client.onConnected = this.onConnect;
    this.client.onDisconnected = this.onDisconnect;
    this.client.connectionMessage = MqttConnectMessage()
        .authenticateAs(this.mqtt_username, this.mqtt_password);
    try {
      await this.client.connect();
      setConnection(true);
    } catch (e) {
      this.setConnection(false);
      this.client.disconnect();
    }

    this.client.updates.listen(this.onSubscribe);
  }

  void onConnect() {
    this.client.subscribe("led/status", MqttQos.atLeastOnce);
  }

  void onDisconnect() {
    setState(() {
      status = 1;
      connected = false;
    });
  }

  void onSubscribe(List<MqttReceivedMessage<MqttMessage>> events) {
    MqttReceivedMessage<MqttMessage> event = events[0];
    MqttPublishMessage message = event.payload;
    String payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);
    String topic = event.topic;
    if (topic == "led/status") {
      setStatus(int.parse(payload));
    }
  }

  void setStatus(int status) {
    setState(() {
      this.status = status;
    });
  }

  void setConnection(bool status) {
    setState(() {
      connected = status;
    });
  }

  void publishStatus(int status) {
    MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(status.toString());
    this.client.publishMessage('led/set', MqttQos.atLeastOnce, builder.payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Led"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: this.connected == true
            ? [
                Text('Connection status: ${this.connected}'),
                Text('Led status: ${this.status == 1 ? 'off' : 'on'}'),
                RaisedButton(
                  onPressed: () => this.publishStatus(this.status == 1 ? 0 : 1),
                  child: Text(this.status == 0 ? 'off' : 'on'),
                )
              ]
            : [
                Text(
                    'Connecting to ${this.mqtt_server} as ${this.mqtt_username} with ${this.mqtt_password}.'),
              ],
      ),
    );
  }
}
