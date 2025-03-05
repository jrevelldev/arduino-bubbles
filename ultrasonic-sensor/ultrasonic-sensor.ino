// Define pins
const int trigPin = 5;
const int echoPin = 6;

// Variable to store the duration and distance
long duration;
int distance;

void setup() {
  // Start the Serial Monitor
  Serial.begin(9600);

  // Set the trigPin as an OUTPUT
  pinMode(trigPin, OUTPUT);

  // Set the echoPin as an INPUT
  pinMode(echoPin, INPUT);
}

void loop() {
  // Ensure the trigPin is LOW to start with
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  // Send a pulse to the trigPin to start measurement
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  // Read the echoPin to get the duration of the pulse
  duration = pulseIn(echoPin, HIGH);

  // Calculate the distance (speed of sound is 34300 cm/s)
  distance = (duration / 2) / 29.1;  // Divide by 2 for the travel distance there and back, and divide by 29.1 for the conversion to cm

  // Check if the distance is too large (over 400 cm, which is beyond the sensor's range)
  if (distance > 400) {
    distance = -1;  // Invalid reading, set to -1 or any other value that makes sense for you
  }

  // Print the distance to the Serial Monitor
  Serial.print("Distance: ");
  if (distance == -1) {
    Serial.println("Out of range");
  } else {
    Serial.print(distance);
    Serial.println(" cm");
  }

  // Wait for a second before taking another measurement
  delay(1000);
}
