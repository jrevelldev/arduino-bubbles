// Main.pde

int phase = 0; // 0 = fade in, 1 = hold, 2 = fade out
int phaseStartTime = 0;
int fadeDuration = 2000;
int holdDuration = 5000;
float alpha = 0;

int distance = -1;
PFont font;
boolean showIntro = true;
int connectDelay = 5000;
int connectStartTime;

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

  if (currentImage != null) {
    tint(255, alpha);
    image(currentImage, width / 2, height / 2);
    noTint();
  }

  drawInfo();
}

void updateAlpha() {
  int now = millis();
  int elapsed = now - phaseStartTime;

  switch (phase) {
    case 0:
      alpha = map(elapsed, 0, fadeDuration, 0, 255);
      if (elapsed >= fadeDuration) {
        alpha = 255;
        phase = 1;
        phaseStartTime = now;
      }
      break;
    case 1:
      alpha = 255;
      if (elapsed >= holdDuration) {
        phase = 2;
        phaseStartTime = now;
      }
      break;
    case 2:
      alpha = map(elapsed, 0, fadeDuration, 255, 0);
      if (elapsed >= fadeDuration) {
        alpha = 0;
        loadNextImage();
      }
      break;
  }
}

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
}

void keyPressed() {
  if (showIntro && (key == 's' || key == 'S')) {
    setSimulate(true);
    showIntro = false;
    println("Simulació activada manualment");
  }
}
