// Main.pde

int phase = 0; // 0 = fade in, 1 = hold, 2 = fade out
int phaseStartTime = 0;
int fadeDuration = 1000;
int holdDuration = 2000;
float alpha = 0;

int distance = -1;
PFont font;
boolean showIntro = true;
int connectDelay = 5000;
int connectStartTime;

float maxBlur = 10;
int minFocusDistance = 30;  // Can be calibrated by user
PImage lastBlurredImage;
int lastBlurredDistance = -1;
float blurLevel = 0;          // current blur amount (used for smoothing)
float targetBlur = 0;         // target blur amount based on distance
float blurLerpSpeed = 0.1;    // between 0 (very slow) and 1 (instant) — tweak as needed

boolean waitingForNext = false;


//////////////////////////
void setup() {
  size(1000, 800);
  imageMode(CENTER);

  font = createFont("Arial", 20);
  textFont(font);
  textAlign(CENTER, CENTER);
  fill(255);

  println("Connecta't a la xarxa WiFi: ESP32-Sensor01");
  println("Contrasenya: Rosa1234");
  println("Esperant connexió... prem S per simular dades");

  connectStartTime = millis();
  loadImages();
  shuffleOrder();
  loadNextImage();
}

//////////////////////////
void draw() {
  background(0);

  if (showIntro) {
    int elapsed = millis() - connectStartTime;
    int remaining = (connectDelay - elapsed) / 1000;

    textSize(24);
    text("Connecta't a la WiFi: ESP32-Sensor01", width/2, height/2 - 60);
    text("Contrasenya: Rosa1234", width/2, height/2 - 20);
    text("Connectant en: " + max(0, remaining) + " segons...", width/2, height/2 + 40);
    text("Prem S per simular dades", width/2, height/2 + 80);


    if (elapsed >= connectDelay) {
      showIntro = false;
    }
    return;
  }

  int d = getDistance();
  if (d != -1) distance = d;

  updateAlpha();
  
    if (waitingForNext) {
      loadNextImage();
      lastBlurredImage = null;
      lastBlurredDistance = -1;
      waitingForNext = false;
    }

  if (currentImage != null) {
      targetBlur = map(distance, minFocusDistance, maxDistance, 0, maxBlur);
      targetBlur = constrain(targetBlur, 0, maxBlur);
      blurLevel = lerp(blurLevel, targetBlur, blurLerpSpeed);
      
      if (abs(blurLevel - lastBlurredDistance) > 1 || lastBlurredImage == null) {
        lastBlurredImage = getBlurredVersion(currentImage, blurLevel);
        lastBlurredDistance = int(blurLevel);
      }
    tint(255, alpha);
    image(lastBlurredImage, width / 2, height / 2);
    //noTint();    
  }

  drawInfo();
}

//////////////////////
void updateAlpha() {
  int now = millis();
  int elapsed = now - phaseStartTime;

  switch (phase) {
    case 0: //fade in
      alpha = map(elapsed, 0, fadeDuration, 0, 255);
      if (elapsed >= fadeDuration) {
        alpha = 255;
        phase = 1;
        phaseStartTime = now;
      }
      break;
      
    case 1:  //hold
      alpha = 255;
      if (elapsed >= holdDuration) {
        phase = 2;
        phaseStartTime = now;
      }
      break;
      
    case 2:  // fade out
      alpha = map(elapsed, 0, fadeDuration, 255, 0);
      if (elapsed >= fadeDuration) {
        alpha = 0;
        waitingForNext = true;
        //loadNextImage();
        phase = 0;
        phaseStartTime = now;
      }
      break;
  }
}

//////////////////
PImage getBlurredVersion(PImage img, float blurAmt) {
  if (img == null) return null;
  blurAmt = constrain(blurAmt, 0, maxBlur);
  PGraphics pg = createGraphics(img.width, img.height);
  pg.beginDraw();
  pg.image(img, 0, 0);
  pg.filter(BLUR, blurAmt);
  pg.endDraw();
  return pg.get();
}

//////////////////
void drawInfo() {
  textAlign(RIGHT, TOP);
  textSize(16);
  fill(255);

  text("Distància: " + (distance != -1 ? distance + " cm" : "--"), width - 20, 20);
  if (isSimulated()) {
    fill(180);
    text("[Dades simulades]", width - 20, 45);
    fill(255);
  }
  text("Focus threshold: " + minFocusDistance + " cm", width - 20, 65);

}

/////////////////////
void keyPressed() {
  if (showIntro && (key == 's' || key == 'S')) {
    setSimulate(true);
    showIntro = false;
    println("Simulació activada manualment");
  }
  if (key == 'c' || key == 'C') {
    if (distance > 0) {
      minFocusDistance = distance;
      println("Focus calibration set to distance: " + minFocusDistance);
    }
  }
}
