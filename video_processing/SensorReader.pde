// SensorReader.pde

boolean simulate = false;
int lastSensorRead = 0;
int sensorInterval = 100;
String incomingData = "";
final int maxDistance = 200;

// Cyclic simulation logic
int simulatedDistance = 0;
boolean goingUp = true;
int holdUntil = 0;
boolean holding = false;

int getDistance() {
  if (millis() - lastSensorRead < sensorInterval) return -1;
  lastSensorRead = millis();

  if (simulate) {
    int now = millis();

    if (holding) {
      if (now >= holdUntil) {
        holding = false;
        goingUp = !goingUp;
      }
    } else {
      int step = 1000;  // << increase this to speed up
      simulatedDistance += goingUp ? 1 : -1;
      simulatedDistance = constrain(simulatedDistance, 0, maxDistance);

      if (simulatedDistance == 0 || simulatedDistance == maxDistance) {
        holding = true;
        holdUntil = now + int(random(5000, 10000)); // hold 5–10 sec
      }
    }

    incomingData = str(simulatedDistance);
    return simulatedDistance;
  }

  // Real sensor read
  try {
    String[] result = loadStrings("http://192.168.10.3/data");
    if (result != null && result.length > 0) {
      incomingData = result[0].trim();
      if (incomingData.equals("Out of range")) return maxDistance;
      return int(incomingData);
    }
  } catch (Exception e) {
    println("⚠️ No ESP detected. Use 'S' to activate simulation.");
  }

  return -1;
}

boolean isSimulated() {
  return simulate;
}

void setSimulate(boolean value) {
  simulate = value;
}
