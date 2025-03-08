import processing.serial.*;  // Import the serial library

Serial myPort;  // Serial object to communicate with Arduino
String incomingData = "";  // String to store incoming data
PImage img;  // Image to be displayed
int blurAmount = 0;  // Amount of blur to apply

void setup() {
  size(800, 600);  // Set the window size
  img = loadImage("image.png");  // Load an image (place it in the data folder)
  
  // List available serial ports and open the correct one
  String portName = Serial.list()[1];  // Choose the correct port (adjust if necessary)
  myPort = new Serial(this, portName, 9600);  // Open serial port at 9600 baud rate

  println("Available ports:");
  println(Serial.list());
}

void draw() {
  background(255);  // Clear the screen with a white background
  
  // Check if there’s data available from the Arduino
  if (myPort.available() > 0) {
    incomingData = myPort.readStringUntil('\n');  // Read data until newline character
    if (incomingData != null) {
      incomingData = trim(incomingData);  // Remove any extra spaces
      println("Distance from Arduino: " + incomingData + " cm");

      // Convert distance to an integer
      int distance = int(incomingData);
      
      // Map distance to blur amount (assuming 10cm is sharp, 100cm is maximum blur)
      blurAmount = int(map(distance, 10, 100, 0, 10));  
      blurAmount = constrain(blurAmount, 0, 10);  // Ensure blur is within limits
    }
  }
  
  // Apply blur effect
  PImage blurredImg = img.copy();  // Create a copy of the original image
  blurredImg.filter(BLUR, blurAmount);  // Apply blur effect
  
  // Display the image
  image(blurredImg, 0, 0, width, height);

  // Display the incoming distance
  fill(0);
  textSize(32);
  text("Distance: " + incomingData + " cm", 20, height - 50);
}
