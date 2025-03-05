import processing.video.*;
import processing.serial.*;

Serial myPort;  // Create object from Serial class
Movie video;     // Movie object to play video
int distance = 0;  // Distance read from Arduino
float blurAmount = 0;  // Amount of blur to apply (float to allow decimal values)

void setup() {
  // Initialize serial communication
  String portName = Serial.list()[0];  // Change index if necessary, e.g. [1] or [2]
  myPort = new Serial(this, portName, 9600);

  // Load video from "data" folder
  video = new Movie(this, "video.mp4");  // Make sure to use the correct file name

  // Check if the video is loaded
  if (video != null) {
    println("Video loaded successfully!");
    video.loop();  // Loop the video
  } else {
    println("Failed to load the video.");
  }

  // Set the window size to match video resolution (adjust as needed)
  size(480, 480);
}

void draw() {
  // Read serial data
  if (myPort.available() > 0) {
    String val = myPort.readStringUntil('\n');  // Read the incoming data until a newline character
    if (val != null) {
      distance = int(trim(val));  // Parse the distance value
    }
  }

  // Map the distance to blur intensity (0 to 10)
  blurAmount = map(distance, 0, 400, 0, 10);  // Map the distance to a blur value (0 to 10)

  // Display the video
  image(video, 0, 0, width, height);

  // Apply the blur effect
  filter(BLUR, blurAmount);
}

// Handle video events
void movieEvent(Movie m) {
  m.read();  // Read the next video frame
}
