// Main.pde

int phase = 0; // 0 = fade in, 1 = hold, 2 = fade out
int phaseStartTime = 0;
int fadeDuration = 2000;
int holdDuration = 8000;
float alpha = 0;

int distance = -1;
PFont font;
boolean loadingImages = false;
boolean showIntro = true;
int connectDelay = 5000;
int connectStartTime;

float maxBlur = 10;
int minFocusDistance = 30;  // Can be calibrated by user
//PImage lastBlurredImage;
//int lastBlurredDistance = -1;
float blurLevel = 0;          // current blur amount (used for smoothing)
float targetBlur = 0;         // target blur amount based on distance
float blurLerpSpeed = 0.1;    // between 0 (very slow) and 1 (instant) — tweak as needed

//PImage currentImage;
PImage sharpImage;
PImage blurredImage;

//boolean waitingForNext = false;


//////////////////////////
void setup() {
  size(1000, 800);
  imageMode(CENTER);

  font = loadFont("Arial-20.vlw");
  textFont(font);
  textAlign(CENTER, CENTER);
  fill(255);

  background(0);
  text("Carregant imatges...", width / 2, height / 2);
  println("Carregant imatges...");
  delay(500); // ⏳ Give user time to see it before loading

  loadingImages = true;

  connectStartTime = millis();
  showIntro = false;
  
  //loadImages();
  shuffleOrder();
  //loadNextImage();
}

//////////////////////////
void draw() {
  background(0);

// --------- PHASE 1: Loading images ---------
  if (loadingImages) {
    textAlign(CENTER, CENTER);
    textSize(24);
    fill(255);
    text("Carregant imatges...", width / 2, height / 2);

    loadImages();        // Only once
    shuffleOrder();
    loadingImages = false;

    // Start intro timer now
    connectStartTime = millis();
    showIntro = true;
    return;
  }

  // Show intro screen if still in countdown
  if (showIntro) {
    int elapsed = millis() - connectStartTime;
    int remaining = (connectDelay - elapsed) / 1000;

    textSize(24);
    textAlign(CENTER, CENTER);
    fill(255);
    
    text("Connecta't a la WiFi: ESP32-Sensor01", width/2, height/2 - 60);
    text("Contrasenya: Rosa1234", width/2, height/2 - 20);
    text("Connectant en: " + max(0, remaining) + " segons...", width/2, height/2 + 40);
    text("Prem S per simular dades", width/2, height/2 + 80);
    
    println("Connecta't a la xarxa WiFi: ESP32-Sensor01");
    println("Contrasenya: Rosa1234");
    println("Esperant connexió... prem S per simular dades");

    if (elapsed >= connectDelay) {
      showIntro = false;
      phaseStartTime = millis(); // start fade-in phase
      loadNextImage(); // Only load after intro finishes
    }
    
    return;
  }

  // --------- PHASE 3: Main operation ---------
  // Sensor reading
  int d = getDistance();
  if (d != -1) distance = d;

  updateAlpha();
  updateBlurLevel();

  if (currentImage != null && sharpImage != null && blurredImage != null) {
    tint(255, alpha);
    blendImages(sharpImage, blurredImage, blurLevel / maxBlur);
    noTint();
  }

  drawInfo();
}

/*
  // Only draw image if we have both versions
  if (currentImage != null && currentBlurred != null) {
    // Calculate blur blend factor: 0 = sharp, 1 = fully blurred
    float blurFactor = map(distance, minFocusDistance, maxDistance, 0, 1);
    blurFactor = constrain(blurFactor, 0, 1);

    // First draw the sharp image with alpha based on sharpness
    tint(255, alpha * (1 - blurFactor));
    image(currentImage, width / 2, height / 2);

    // Then draw the blurred image on top with complementary alpha
    tint(255, alpha * blurFactor);
    image(currentBlurred, width / 2, height / 2);

    noTint(); // Reset tint
  }

  // Overlay info
  drawInfo();

  // Handle next image if needed
  if (waitingForNext) {
    loadNextImage();
    waitingForNext = false;
  }
}
*/
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
        //waitingForNext = true;
        loadNextImage();
        phase = 0;
        phaseStartTime = now;
      }
      break;
  }
}
////////--/////////////
void updateBlurLevel() {
  targetBlur = map(distance, minFocusDistance, maxDistance, 0, maxBlur);
  targetBlur = constrain(targetBlur, 0, maxBlur);
  blurLevel = lerp(blurLevel, targetBlur, blurLerpSpeed);
}

void blendImages(PImage sharp, PImage blur, float amt) {
  amt = constrain(amt, 0, 1);
  tint(255, alpha * (1 - amt));
  image(sharp, width / 2, height / 2);
  tint(255, alpha * amt);
  image(blur, width / 2, height / 2);
}

//////////////////
/*
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
*/
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
  if (key == 's' || key == 'S') {
    setSimulate(true);
   if (loadingImages) return; // don't skip during loading

    if (showIntro) {
      showIntro = false;
      phaseStartTime = millis();
      loadNextImage();
      println("Simulació activada manualment");
    }
  }
 
  if (key == 'c' || key == 'C') {
    if (distance > 0) {
      minFocusDistance = distance;
      println("Focus calibration set to distance: " + minFocusDistance);
    }
  }
}
