import processing.serial.*;  // Import the serial library

Serial myPort;  // Serial object to communicate with Arduino
String incomingData = "";  // String to store incoming data
PImage img;  // Image to be displayed
float blurAmount = 0;  // Amount of blur to apply (float for smooth transition)
float targetBlur = 0;  // Target blur value from distance

void setup() {
  size(600, 650);  // Set the window size (600px for image + extra space for text)
  img = loadImage("image.png");  // Load the image (make sure it's in the 'data' folder)
  
  // List available serial ports and open the correct one
  String portName = Serial.list()[1];  // Choose the correct port (adjust if necessary)
  myPort = new Serial(this, portName, 9600);  // Open serial port at 9600 baud rate

  println("Available ports:");
  println(Serial.list());
}

void draw() {
  background(0);  // Black background for contrast
  
  // Check if there’s data available from the Arduino
  if (myPort.available() > 0) {
    incomingData = myPort.readStringUntil('\n');  // Read data until newline character
    if (incomingData != null) {
      incomingData = trim(incomingData);  // Remove any extra spaces
      println("Distance from Arduino: " + incomingData + " cm");

      // Convert distance to an integer
      int distance = int(incomingData);
      
      // Map distance to a target blur amount (10cm = sharp, 100cm = max blur)
      targetBlur = map(distance, 10, 100, 0, 10);
      targetBlur = constrain(targetBlur, 0, 10);  // Ensure it stays within limits
    }
  }
  
  // Smoothly transition blur using interpolation
  blurAmount = lerp(blurAmount, targetBlur, 0.1);  // Adjust 0.1 for faster/slower transition

  // Apply blur effect
  PImage blurredImg = img.copy();  // Create a copy of the original image
  blurredImg.filter(BLUR, blurAmount);  // Apply smooth blur effect
  
  // Display the image centered
  image(blurredImg, 0, 0, 600, 600);

  // Display the distance text underneath the image
  fill(255);  // White text
  textSize(10);  // 10pt font size
  textAlign(CENTER, CENTER);
  text("Distance: " + incomingData + " cm", width / 2, height - 25);
}
