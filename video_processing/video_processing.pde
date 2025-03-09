import processing.serial.*;  // Import the serial library

Serial myPort;  // Serial object to communicate with Arduino
String incomingData = "";  // String to store incoming data
PImage img;  // Original image
PImage blurredImg;  // Pre-blurred image
PImage maskImg;  // The mask overlay
float blurAmount = 0;  // Current blur level (float for smooth transition)
float targetBlur = 0;  // Target blur value from distance

// Variables for dragging
float imgX, imgY;  // Image position
boolean dragging = false;  // Is the image being dragged?
float offsetX, offsetY;  // Mouse offset when dragging
boolean blurUpdated = true;  // Track if we need to reapply blur

void setup() {
  size(1000, 1000);  // Set window size
  img = loadImage("image.png");  // Load the image (ensure it's in the 'data' folder)
  maskImg = loadImage("mask.png");  // Load the mask image (ensure it's in the 'data' folder)
  blurredImg = img.copy();  // Start with an initial blurred image

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

  // Read Arduino distance **only when new data arrives** and if NOT dragging
  if (!dragging && myPort.available() > 0) {
    incomingData = myPort.readStringUntil('\n');  // Read data until newline character
    if (incomingData != null) {
      incomingData = trim(incomingData);  // Remove any extra spaces
      println("Distance from Arduino: " + incomingData + " cm");

      // ✅ Fix: Now closer = sharp, farther = blurry
      float newTargetBlur = map(int(incomingData), 10, 100, 15, 0);
      newTargetBlur = constrain(newTargetBlur, 0, 15);  // Ensure within limits

      // Only update blur if the target value changes
      if (newTargetBlur != targetBlur) {
        targetBlur = newTargetBlur;
        blurUpdated = true;  // Mark that we need to update the blur
      }
    }
  }
  
  // Smoothly transition blur using interpolation **if not dragging**
  if (!dragging) {
    blurAmount = lerp(blurAmount, targetBlur, 0.1);  // Adjust 0.1 for faster/slower transition
  }

  // **Only apply blur when needed** (improves performance)
  if (blurUpdated && !dragging) {
    blurredImg = img.copy();  // Create a new copy of the original image
    blurredImg.filter(BLUR, blurAmount);  // Apply blur effect
    blurUpdated = false;  // Reset the flag
  }

  // ✅ Display the blurred image at its original size (600x600) without scaling
  image(blurredImg, imgX, imgY, 600, 600);

  // ✅ Overlay the mask **at the same position as the image**
  image(maskImg, imgX, imgY, 600, 600);

  // Display the distance text **fixed at the top-left**
  fill(255);  // White text
  textSize(10);  // 10pt font size
  textAlign(LEFT, TOP);
  text("Distance: " + incomingData + " cm", 10, 10);
}

// Mouse pressed - Check if clicking inside the image
void mousePressed() {
  if (mouseX > imgX && mouseX < imgX + 600 && mouseY > imgY && mouseY < 600 + imgY) {
    dragging = true;
    offsetX = mouseX - imgX;
    offsetY = mouseY - imgY;
  }
}

// Mouse dragged - Move the image **without lag**
void mouseDragged() {
  if (dragging) {
    imgX = mouseX - offsetX;
    imgY = mouseY - offsetY;
  }
}

// Mouse released - Stop dragging and update blur
void mouseReleased() {
  dragging = false;
  blurUpdated = true;  // Reapply blur after dragging stops
}
