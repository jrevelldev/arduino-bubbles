import processing.serial.*;  // Import the serial library

Serial myPort;  // Import Serial communication
String incomingData = "";  // String to store incoming data
PImage img;  // Original image
PImage blurredImg;  // Pre-blurred image
PImage maskImg;  // The mask overlay
float blurAmount = 0;  // Current blur level (float for smooth transition)
float targetBlur = 0;  // Target blur value from distance

// Calibration Variables
int minCalibratedDistance = 10;  // Default close distance (sharp)
final int maxDistance = 400;  // Always the farthest distance (blurry)

// Variables for dragging
float imgX, imgY;  // Image position
boolean dragging = false;  // Is the image being dragged?
boolean editingPerspective = false;  // Are we editing perspective?
float offsetX, offsetY;  // Mouse offset when dragging

// Corner points for perspective deformation
PVector[] corners = new PVector[4];
int selectedCorner = -1;  // -1 means no corner is selected

void setup() {
  size(1000, 1000, P2D);  // Use P2D renderer for texture mapping
  img = loadImage("image.png");  // Load the image
  maskImg = loadImage("mask.png");  // Load the mask image
  blurredImg = img.copy();  // Start with an initial blurred image

  // Center the image initially
  imgX = width / 2 - 300;
  imgY = height / 2 - 300;

  // Initialize the four corners of the image
  corners[0] = new PVector(imgX, imgY);  // Top-left
  corners[1] = new PVector(imgX + 600, imgY);  // Top-right
  corners[2] = new PVector(imgX + 600, imgY + 600);  // Bottom-right
  corners[3] = new PVector(imgX, imgY + 600);  // Bottom-left

  // Set up serial communication
  String portName = Serial.list()[1];  // Choose the correct port
  myPort = new Serial(this, portName, 9600);  

  println("Available ports:");
  println(Serial.list());
}

void draw() {
  background(0);

  // Read Arduino distance only when new data arrives and if NOT dragging
  if (!dragging && !editingPerspective && myPort.available() > 0) {
    incomingData = myPort.readStringUntil('\n');  
    if (incomingData != null) {
      incomingData = trim(incomingData);
      println("Distance from Arduino: " + incomingData + " cm");

      int currentDistance = int(incomingData);
      
      // Ensure the calibration min is valid (less than max)
      if (minCalibratedDistance >= maxDistance) {
        minCalibratedDistance = maxDistance - 1;
      }

      // Adjust blur based on new calibration
      float newTargetBlur = map(currentDistance, minCalibratedDistance, maxDistance, 0, 15);
      newTargetBlur = constrain(newTargetBlur, 0, 15);

      if (newTargetBlur != targetBlur) {
        targetBlur = newTargetBlur;
        blurredImg = img.copy();
        blurredImg.filter(BLUR, targetBlur);
      }
    }
  }

  // Smoothly transition blur
  if (!dragging && !editingPerspective) {
    blurAmount = lerp(blurAmount, targetBlur, 0.1);
  }

  // Apply perspective distortion using beginShape() and texture()
  beginShape();
  texture(blurredImg);
  vertex(corners[0].x, corners[0].y, 0, 0);  
  vertex(corners[1].x, corners[1].y, blurredImg.width, 0);  
  vertex(corners[2].x, corners[2].y, blurredImg.width, blurredImg.height);  
  vertex(corners[3].x, corners[3].y, 0, blurredImg.height);  
  endShape(CLOSE);

  // Draw the mask on top of the warped image
  beginShape();
  texture(maskImg);
  vertex(corners[0].x, corners[0].y, 0, 0);
  vertex(corners[1].x, corners[1].y, maskImg.width, 0);
  vertex(corners[2].x, corners[2].y, maskImg.width, maskImg.height);
  vertex(corners[3].x, corners[3].y, 0, maskImg.height);
  endShape(CLOSE);

  // Draw the distance text in the top-left
  fill(255);
  textSize(10);
  textAlign(LEFT, TOP);
  text("Distance: " + incomingData + " cm", 10, 10);
  text("Calibrated Min Distance: " + minCalibratedDistance + " cm", 10, 25);  // Show calibrated value

  // Draw control points and red bounding box if editing perspective
  if (editingPerspective) {
    stroke(255, 0, 0);  // Red outline
    strokeWeight(2);
    noFill();
    beginShape();
    for (PVector corner : corners) {
      vertex(corner.x, corner.y);
    }
    endShape(CLOSE); 

    // Draw control points
    fill(255, 0, 0);
    noStroke();
    for (PVector corner : corners) {
      ellipse(corner.x, corner.y, 10, 10);
    }
  }
}

// Mouse pressed - Start dragging or enter edit mode
void mousePressed() {
  if (pointInQuad(mouseX, mouseY, corners)) {
    editingPerspective = true;
  } else {
    editingPerspective = false;
  }

  selectedCorner = -1;
  for (int i = 0; i < corners.length; i++) {
    if (dist(mouseX, mouseY, corners[i].x, corners[i].y) < 10) {
      selectedCorner = i;
      break;
    }
  }
}

// Mouse dragged - Move a corner or the whole image
void mouseDragged() {
  if (selectedCorner != -1) {
    corners[selectedCorner].x = mouseX;
    corners[selectedCorner].y = mouseY;
  }
}

// Mouse released - Stop dragging
void mouseReleased() {
  selectedCorner = -1;
}

// Keyboard pressed - Calibrate minimum distance
void keyPressed() {
  if (key == 'c' || key == 'C') {
    if (incomingData != null && incomingData.length() > 0) {
      minCalibratedDistance = int(incomingData);  // Set new calibration
      println("Calibrated Minimum Distance Set to: " + minCalibratedDistance + " cm");
    }
  }
}

// Utility function to check if a point is inside a quadrilateral
boolean pointInQuad(float px, float py, PVector[] quad) {
  float sumAngles = 0;
  for (int i = 0; i < quad.length; i++) {
    PVector v1 = PVector.sub(quad[i], new PVector(px, py));
    PVector v2 = PVector.sub(quad[(i + 1) % quad.length], new PVector(px, py));
    sumAngles += PVector.angleBetween(v1, v2);
  }
  return abs(sumAngles - TWO_PI) < 0.1;
}
