#include <WiFi.h>

// Pins del sensor
const int trigPin = 12;
const int echoPin = 14;

long duration;
int distance;

// Configura xarxa privada (Access Point)
const char* ssid = "ESP32-Sensor01";
const char* password = "Rosa1234";

WiFiServer server(80);

void setup() {
  Serial.begin(115200);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  IPAddress local_IP(192, 168, 10, 1);        // Nova IP fixa
  IPAddress gateway(192, 168, 10, 1);         // S'acostuma a ser la mateixa
  IPAddress subnet(255, 255, 255, 0);         // Subxarxa estàndard

  WiFi.softAPConfig(local_IP, gateway, subnet);

  // Crea la xarxa WiFi pròpia
  WiFi.softAP(ssid, password);

  // Mostra la IP del servidor
  IPAddress IP = WiFi.softAPIP();
  Serial.println("Xarxa creada.");
  Serial.print("Connecta't a la xarxa: ");
  Serial.println(ssid);
  Serial.print("IP del servidor: ");
  Serial.println(IP);

  server.begin();
}

void loop() {
  // Mesura distància
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH);
  distance = (duration / 2) / 29.1;
  if (distance > 400) distance = -1;

  // Atén peticions web
  WiFiClient client = server.available();
  if (client) {
    //Serial.println("Client connectat");

    // Espera fins que hi hagi dades
    while (client.connected() && !client.available()) delay(1);

    String request = client.readStringUntil('\r');
    Serial.print("Petició: ");
    Serial.println(request);
    client.readStringUntil('\n'); // Neteja

    // Resposta per AJAX (fetch /dades)
    if (request.indexOf("GET /data") >= 0) {
      String data;
      if (distance == -1) {
        data = "Out of range";
      } else {
        data = String(distance);
      }
      client.print("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n");
      client.print(data);
    }

    // Resposta principal (HTML)
    else {
      String html = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n";
      html += "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Distància</title>";
      html += "<style>body{font-family:sans-serif;text-align:center;margin-top:50px;}</style>";
      html += "<script>";
      html += "setInterval(function() {";
      html += "fetch('/dades').then(r => r.text()).then(t => {";
      html += "document.getElementById('dist').innerHTML = t;";
      html += "});";
      html += "}, 1000);";
      html += "</script></head><body>";
      html += "<h1>📏 Distància amb ultrasons</h1>";
      html += "<p id='dist'>Carregant...</p>";
      html += "</body></html>";

      client.print(html);
    }

    delay(1);
    client.stop();
    //Serial.println("Client desconnectat");
  }

  delay(100); // Freqüència de mesura
}
