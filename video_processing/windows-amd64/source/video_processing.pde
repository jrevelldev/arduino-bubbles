import processing.serial.*;
import java.io.File;

// Serial and sensor data
Serial myPort;
String incomingData = "";

// Images and random selection
ArrayList<PImage> images = new ArrayList<PImage>();
ArrayList<String> imageNames = new ArrayList<String>();
ArrayList<Integer> availableIndices = new ArrayList<Integer>();
int currentImageIndex = -1;
PImage maskImg;

// Blur & scaling
float blurAmount = 0;
float targetBlur = 0;
float blurTransitionSpeed = 0.5; //was 0.1

int minCalibratedDistance = 10; // User calibrated min distance
final int maxDistance = 200;    // Max distance (furthest)

// UI & deformation
boolean wifiInstructionsShown = true;
int wifiInstructionsUntil = 0;

boolean editingPerspective = false;
boolean showInfo = true;

PVector[] corners = new PVector[4];
int selectedCorner = -1;

// Scaling values
float scaleAmount = 1.0;
float targetScale = 1.0;
float scaleTransitionSpeed = 0.1;

// Fade between images
float alphaValue = 0;
float fadeSpeed = 50; //més gran = mes rapid
int phase = 0; // 0 = fade in, 1 = hold, 2 = fade out
int holdTime = 10000; // milliseconds
int lastPhaseTime = 0;

void setup() {
  size(1000, 1000, P2D);

  loadImages();

  if (images.size() == 0) {
    println("No images found! Exiting...");
    exit();
  }

  resetImagePool();
  nextRandomImage();

  maskImg = loadImage("mask.png");

  loadCorners();  // Load saved corners if they exist

  lastPhaseTime = millis();

  println("Available ports:");
  println(Serial.list());
  
  wifiInstructionsUntil = millis() + 5000;  // mostra missatge durant 5 segons abans de connectar-se
  println("Connecta't a la xarxa WiFi: ESP32-Sensor01");
  println("Contrasenya: Rosa1234");
  println("Esperant connexió... el programa intentarà connectar-se en 10 segons");
}

void draw() {

  if (wifiInstructionsShown) {
  background(0);
  fill(255);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("Connectto WiFi network: ESP32-Sensor01/02/03\n Password: Rosa1234\n\nProgram will begin automatically...", width / 2, height / 2);

  if (millis() > wifiInstructionsUntil) {
    wifiInstructionsShown = false;
  }
  return; // Pausa el draw mentre es mostra el missatge
  }
  
  background(0);

  handleSerial();
  handleBlurAndScale();
  handleImageTransition();

  drawMask(); // Draw the mask after the image layer
  drawInfoPanel();

  if (editingPerspective) {
    drawBoundingBox();
    drawControlPoints();
    drawWarpedCircle();
  } else {
    resetStroke();
  }
}

int lastRequestTime = 0;
int requestInterval = 100; // ms

void handleSerial() {
  if (editingPerspective) return;
  if (millis() - lastRequestTime < requestInterval) return;
  lastRequestTime = millis();

  try {
    String[] result = loadStrings("http://192.168.10.1/data");  // IP fixa del teu ESP32
    if (result != null && result.length > 0) {
      incomingData = result[0].trim();
      int currentDistance = maxDistance;

      if (incomingData.equals("Out of range")) {
        currentDistance = maxDistance;
      } else {
        try {
          currentDistance = int(incomingData);
        } catch (Exception e) {
          currentDistance = maxDistance;
        }
      }

      float newTargetBlur = map(currentDistance, minCalibratedDistance, maxDistance, 0, 15);
      newTargetBlur = constrain(newTargetBlur, 0, 15);
      targetScale = map(newTargetBlur, 0, 15, 1.0, 1.1);

      if (abs(newTargetBlur - targetBlur) > 2) {
        targetBlur = newTargetBlur;
      }
    }
  } catch (Exception e) {
    println("No s'ha pogut connectar a l'ESP32.");
  }
}

void handleBlurAndScale() {
  if (!editingPerspective && abs(blurAmount - targetBlur) > 0.1) {
    blurAmount = lerp(blurAmount, targetBlur, blurTransitionSpeed);
  }

  if (!editingPerspective && abs(scaleAmount - targetScale) > 0.001) {
    scaleAmount = lerp(scaleAmount, targetScale, scaleTransitionSpeed);
  }
}

void handleImageTransition() {
  if (images.size() == 0) return;

  PImage currentImage = images.get(currentImageIndex);
  PImage tempImg = currentImage.copy();

  tempImg.filter(BLUR, blurAmount);

  int now = millis();

  switch (phase) {
    case 0: // Fade in
      alphaValue += fadeSpeed;
      if (alphaValue >= 255) {
        alphaValue = 255;
        phase = 1;
        lastPhaseTime = now;
      }
      break;

    case 1: // Hold
      if (now - lastPhaseTime > holdTime) {
        phase = 2;
      }
      break;

    case 2: // Fade out
      alphaValue -= fadeSpeed;
      if (alphaValue <= 0) {
        alphaValue = 0;
        nextRandomImage();
        phase = 0;
      }
      break;
  }

  tint(255, alphaValue);
  applyScaledWarpedTexture(tempImg, scaleAmount);
  noTint();
}

void nextRandomImage() {
  if (availableIndices.size() == 0) {
    println("All images shown! Resetting sequence...");
    resetImagePool();
  }

  int randomIndex = int(random(availableIndices.size()));
  currentImageIndex = availableIndices.get(randomIndex);
  availableIndices.remove(randomIndex);

  println("Now showing: " + imageNames.get(currentImageIndex));
}

void resetImagePool() {
  availableIndices.clear();
  for (int i = 0; i < images.size(); i++) {
    availableIndices.add(i);
  }
  println("Image pool reset!");
}

void drawMask() {
  float extraSize = 100; // 700 - 600
  float offset = extraSize / 2.0;

  float centerX = (corners[0].x + corners[1].x + corners[2].x + corners[3].x) / 4.0;
  float centerY = (corners[0].y + corners[1].y + corners[2].y + corners[3].y) / 4.0;

  PVector[] maskCorners = new PVector[4];

  for (int i = 0; i < 4; i++) {
    float dx = corners[i].x - centerX;
    float dy = corners[i].y - centerY;

    PVector direction = new PVector(dx, dy);
    direction.normalize();

    maskCorners[i] = new PVector(
      corners[i].x + direction.x * offset,
      corners[i].y + direction.y * offset
    );
  }

  beginShape();
  texture(maskImg);
  vertex(maskCorners[0].x, maskCorners[0].y, 0, 0);
  vertex(maskCorners[1].x, maskCorners[1].y, maskImg.width, 0);
  vertex(maskCorners[2].x, maskCorners[2].y, maskImg.width, maskImg.height);
  vertex(maskCorners[3].x, maskCorners[3].y, 0, maskImg.height);
  endShape(CLOSE);
}

void drawInfoPanel() {
  if (!showInfo) return;

  fill(255);
  textSize(10);
  textAlign(LEFT, TOP);

  text("Distance: " + incomingData + " cm", 10, 10);
  text("Calibrated Min Distance: " + minCalibratedDistance + " cm", 10, 25);
  text("Blur: " + nf(blurAmount, 1, 2), 10, 40);
  text("Scale (image.png): " + nf(scaleAmount, 1, 3), 10, 55);
  text("Current Image: " + imageNames.get(currentImageIndex), 10, 70);
  text("[Press 'C' to calibrate]\n[Press 'H' to hide this info]\n[Press 'R' to reset corners]", 10, 85);

  text("\nLoaded Images:", 10, 130);
  for (int i = 0; i < imageNames.size(); i++) {
    text((i + 1) + ": " + imageNames.get(i), 10, 150 + (i * 15));
  }
}

void loadImages() {
  File folder = new File(dataPath(""));
  File[] files = folder.listFiles();

  if (files == null) {
    println("No files found in the data folder.");
    return;
  }

  for (File file : files) {
    String fileName = file.getName().toLowerCase();
    if (fileName.endsWith(".png") && fileName.startsWith("image")) {
      PImage img = loadImage(file.getName());
      if (img != null) {
        images.add(img);
        imageNames.add(file.getName());
        println("Loaded: " + file.getName());
      }
    }
  }

  if (images.size() == 0) {
    println("No matching images found.");
  }
}

void applyScaledWarpedTexture(PImage tex, float scale) {
  float centerX = (corners[0].x + corners[1].x + corners[2].x + corners[3].x) / 4.0;
  float centerY = (corners[0].y + corners[1].y + corners[2].y + corners[3].y) / 4.0;

  beginShape();
  texture(tex);
  for (int i = 0; i < 4; i++) {
    float dx = corners[i].x - centerX;
    float dy = corners[i].y - centerY;
    float scaledX = centerX + dx * scale;
    float scaledY = centerY + dy * scale;

    if (i == 0)
      vertex(scaledX, scaledY, 0, 0);
    else if (i == 1)
      vertex(scaledX, scaledY, tex.width, 0);
    else if (i == 2)
      vertex(scaledX, scaledY, tex.width, tex.height);
    else if (i == 3)
      vertex(scaledX, scaledY, 0, tex.height);
  }
  endShape(CLOSE);
}

// CORNER SAVE/LOAD FUNCTIONS ------------------------

void saveCorners() {
  String[] lines = new String[corners.length];
  for (int i = 0; i < corners.length; i++) {
    lines[i] = corners[i].x + "," + corners[i].y;
  }
  saveStrings("corners.txt", lines);
  println("Corners saved.");
}

void loadCorners() {
  String[] lines = loadStrings("corners.txt");
  if (lines == null || lines.length != 4) {
    println("No saved corners found. Using defaults.");
    resetCorners();
    return;
  }

  for (int i = 0; i < lines.length; i++) {
    String[] coords = split(lines[i], ",");
    if (coords.length == 2) {
      float x = float(coords[0]);
      float y = float(coords[1]);
      corners[i] = new PVector(x, y);
    }
  }
  println("Corners loaded.");
}

void exit() {
  saveCorners(); // Save on exit
  super.exit();
}

void drawBoundingBox() {
  if (!editingPerspective) return;

  stroke(255, 0, 0);
  strokeWeight(2);
  noFill();
  beginShape();
  for (PVector corner : corners) {
    vertex(corner.x, corner.y);
  }
  endShape(CLOSE);
}

void drawControlPoints() {
  if (!editingPerspective) return;

  fill(255, 0, 0);
  noStroke();
  for (PVector corner : corners) {
    ellipse(corner.x, corner.y, 10, 10);
  }
}

void drawWarpedCircle() {
  if (!editingPerspective) return;

  stroke(0, 255, 0);
  strokeWeight(2);
  noFill();

  beginShape();
  for (int i = 0; i < 360; i += 10) {
    float angle = radians(i);
    float x = cos(angle) * 200 + 500;
    float y = sin(angle) * 200 + 500;

    PVector warped = bilinearInterpolate(x, y);
    vertex(warped.x, warped.y);
  }
  endShape(CLOSE);

  resetStroke();
}

PVector bilinearInterpolate(float x, float y) {
  float u = map(x, 300, 700, 0, 1);
  float v = map(y, 300, 700, 0, 1);

  float newX = lerp(lerp(corners[0].x, corners[1].x, u), lerp(corners[3].x, corners[2].x, u), v);
  float newY = lerp(lerp(corners[0].y, corners[1].y, u), lerp(corners[3].y, corners[2].y, u), v);

  return new PVector(newX, newY);
}

void resetStroke() {
  noStroke();
}

void mousePressed() {
  selectedCorner = -1;

  for (int i = 0; i < corners.length; i++) {
    if (dist(mouseX, mouseY, corners[i].x, corners[i].y) < 10) {
      selectedCorner = i;
      editingPerspective = true;
      return;
    }
  }

  if (pointInQuad(mouseX, mouseY, corners)) {
    editingPerspective = true;
  } else {
    editingPerspective = false;
    resetStroke();
  }
}

void mouseDragged() {
  if (selectedCorner != -1) {
    corners[selectedCorner].x = mouseX;
    corners[selectedCorner].y = mouseY;
  }
}

void mouseReleased() {
  if (selectedCorner != -1) {
    saveCorners(); // Auto-save after dragging (optional)
  }
  selectedCorner = -1;
}

void resetCorners() {
  corners[0] = new PVector(200, 200);
  corners[1] = new PVector(800, 200);
  corners[2] = new PVector(800, 800);
  corners[3] = new PVector(200, 800);
  saveCorners(); // Save reset immediately
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    if (incomingData != null && incomingData.length() > 0) {
      minCalibratedDistance = int(incomingData);
      println("Calibrated Minimum Distance Set to: " + minCalibratedDistance + " cm");
    }
  }

  if (key == 'h' || key == 'H') {
    showInfo = !showInfo;
  }

  if (key == 'r' || key == 'R') {
    resetCorners();
    println("Corners reset to default.");
  }
}

boolean pointInQuad(float px, float py, PVector[] quad) {
  float sumAngles = 0;
  for (int i = 0; i < quad.length; i++) {
    PVector v1 = PVector.sub(quad[i], new PVector(px, py));
    PVector v2 = PVector.sub(quad[(i + 1) % quad.length], new PVector(px, py));
    sumAngles += PVector.angleBetween(v1, v2);
  }
  return abs(sumAngles - TWO_PI) < 0.1;
}
