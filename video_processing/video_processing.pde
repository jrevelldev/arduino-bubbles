import processing.serial.*;  // Import the serial library

Serial myPort;  // Serial object to communicate with Arduino
String incomingData = "";  // String to store incoming data
PImage img;  // Image to be displayed
float blurAmount = 0;  // Amount of blur to apply (float for smooth transition)
float targetBlur = 0;  // Target blur value from distance

// Variables for dragging
float imgX, imgY;  // Image position
boolean dragging = false;  // Is the image being dragged?
float offsetX, offsetY;  // Mouse offset when dragging

void setup() {
  size(1000, 1000);  // Set window size
  img = loadImage("image.png");  // Load the image (make sure it's in the 'data' folder)

  // Center the image initially
  imgX = width / 2 - 300;  // Center X (600px wide, so offset by 300)
  imgY = height / 2 - 300;  // Center Y (600px high, so offset by 300)

  // Set up serial communication
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
  
  // Display the image at current position
  image(blurredImg, imgX, imgY, 600, 600);

  // Display the distance text underneath the image
  fill(255);  // White text
  textSize(10);  // 10pt font size
  textAlign(CENTER, CENTER);
  text("Distance: " + incomingData + " cm", width / 2, imgY + 630); // Text below the image
}

// Mouse pressed - Check if clicking inside the image
void mousePressed() {
  if (mouseX > imgX && mouseX < imgX + 600 && mouseY > imgY && mouseY < imgY + 600) {
    dragging = true;
    offsetX = mouseX - imgX;
    offsetY = mouseY - imgY;
  }
}

// Mouse dragged - Move the image
void mouseDragged() {
  if (dragging) {
    imgX = mouseX - offsetX;
    imgY = mouseY - offsetY;
  }
}

// Mouse released - Stop dragging
void mouseReleased() {
  dragging = false;
}
