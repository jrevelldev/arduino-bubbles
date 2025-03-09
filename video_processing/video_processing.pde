import processing.serial.*;  

Serial myPort;  
String incomingData = "";  
PImage img;  
PImage blurredImg;  
PImage maskImg;  
float blurAmount = 0;  
float targetBlur = 0;  
float blurTransitionSpeed = 0.1;  

int minCalibratedDistance = 10;  
final int maxDistance = 400;  

boolean editingPerspective = false;  

PVector[] corners = new PVector[4];  
int selectedCorner = -1;  

void setup() {
  size(1000, 1000, P2D);  
  img = loadImage("image.png");  
  maskImg = loadImage("mask.png");  
  blurredImg = img.copy();  

  resetCorners();  

  String portName = Serial.list()[1];  
  myPort = new Serial(this, portName, 9600);  

  println("Available ports:");
  println(Serial.list());
}

void draw() {
  background(0);

  if (!editingPerspective && myPort.available() > 0) {
    incomingData = myPort.readStringUntil('\n');  
    if (incomingData != null) {
      incomingData = trim(incomingData);
      println("Distance from Arduino: " + incomingData + " cm");

      int currentDistance = int(incomingData);
      
      if (minCalibratedDistance >= maxDistance) {
        minCalibratedDistance = maxDistance - 1;
      }

      float newTargetBlur = map(currentDistance, minCalibratedDistance, maxDistance, 0, 15);
      newTargetBlur = constrain(newTargetBlur, 0, 15);

      if (abs(newTargetBlur - targetBlur) > 2) {  
        targetBlur = newTargetBlur;
      }
    }
  }

  if (!editingPerspective && abs(blurAmount - targetBlur) > 0.1) {  
    blurAmount = lerp(blurAmount, targetBlur, blurTransitionSpeed);
    blurredImg = img.copy();
    blurredImg.filter(BLUR, blurAmount);
  }

  applyWarpedTexture(blurredImg);
  applyWarpedTexture(maskImg);

  fill(255);
  textSize(10);
  textAlign(LEFT, TOP);
  text("Distance: " + incomingData + " cm", 10, 10);
  text("Calibrated Min Distance: " + minCalibratedDistance + " cm", 10, 25);
  text("Blur: " + nf(blurAmount, 1, 2), 10, 40);

  if (editingPerspective) {
    drawBoundingBox();
    drawControlPoints();
    drawWarpedCircle();
  }
}

void applyWarpedTexture(PImage tex) {
  beginShape();
  texture(tex);
  vertex(corners[0].x, corners[0].y, 0, 0);
  vertex(corners[1].x, corners[1].y, tex.width, 0);
  vertex(corners[2].x, corners[2].y, tex.width, tex.height);
  vertex(corners[3].x, corners[3].y, 0, tex.height);
  endShape(CLOSE);
}

void drawBoundingBox() {
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
  fill(255, 0, 0);
  noStroke();
  for (PVector corner : corners) {
    ellipse(corner.x, corner.y, 10, 10);
  }
}

// **New Function to Draw a Properly Warped Circle**
void drawWarpedCircle() {
  stroke(0, 255, 0);
  strokeWeight(2);
  noFill();
  
  beginShape();
  for (int i = 0; i < 360; i += 10) {  // Generate circle points
    float angle = radians(i);
    float x = cos(angle) * 200 + 500;  
    float y = sin(angle) * 200 + 500;
    
    // Apply proper perspective mapping
    PVector warped = bilinearInterpolate(x, y);
    vertex(warped.x, warped.y);
  }
  endShape(CLOSE);
}

// **Warp a point to match the distorted quadrilateral using bilinear interpolation**
PVector bilinearInterpolate(float x, float y) {
  float u = map(x, 300, 700, 0, 1);  
  float v = map(y, 300, 700, 0, 1);  

  float newX = lerp(lerp(corners[0].x, corners[1].x, u), lerp(corners[3].x, corners[2].x, u), v);
  float newY = lerp(lerp(corners[0].y, corners[1].y, u), lerp(corners[3].y, corners[2].y, u), v);

  return new PVector(newX, newY);
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
  }
}

void mouseDragged() {
  if (selectedCorner != -1) {
    corners[selectedCorner].x = mouseX;
    corners[selectedCorner].y = mouseY;
  }
}

void mouseReleased() {
  selectedCorner = -1;
}

void resetCorners() {
  corners[0] = new PVector(200, 200);  
  corners[1] = new PVector(800, 200);
  corners[2] = new PVector(800, 800);
  corners[3] = new PVector(200, 800);
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    if (incomingData != null && incomingData.length() > 0) {
      minCalibratedDistance = int(incomingData);
      println("Calibrated Minimum Distance Set to: " + minCalibratedDistance + " cm");
    }
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
