import java.io.File;
import java.util.Collections;
import java.util.Arrays;
import java.util.List;

PImage[] images;
int imgIndex = 0;
PImage currentImg;

int phase = 0;  // 0 = fade in, 1 = hold, 2 = fade out
int phaseFrame = 0;
int fps = 25;

int fadeDuration = int(2 * fps);    // 2 seconds fade in/out
int holdDuration = int(5 * fps);    // 5 seconds hold

float blurAmount = 20;
int totalImages = 0;
boolean done = false;

public void settings() {
  size(500, int(500 * 1633.0 / 2177.0));  // 500 × 375
}

void setup() {
  frameRate(fps);

  ArrayList<PImage> tempList = new ArrayList<PImage>();

  String[] folders = {
    "images/folder1",
    "images/folder2",
    "images/folder3",
    "images/folder4"
  };

  for (String folder : folders) {
    File dir = new File(dataPath(folder));
    if (dir.exists()) {
      for (File f : dir.listFiles()) {
        if (f.isFile() && (f.getName().endsWith(".jpg") || f.getName().endsWith(".png"))) {
          tempList.add(loadImage(folder + "/" + f.getName()));
        }
      }
    }
  }

  images = tempList.toArray(new PImage[0]);

  // Shuffle the images
  List<PImage> imgList = Arrays.asList(images);
  Collections.shuffle(imgList);
  images = imgList.toArray(new PImage[0]);

  totalImages = images.length;
  loadNextImage();
}

void draw() {
  if (done) {
    exit();
    return;
  }

  background(0);

  float alpha = 255;
  float blurLevel = 0;

  if (phase == 0) {  // fade in
    float pct = phaseFrame / float(fadeDuration);
    blurLevel = lerp(blurAmount, 0, pct);
    alpha = lerp(0, 255, pct);
  } else if (phase == 1) {  // hold
    blurLevel = 0;
    alpha = 255;
  } else if (phase == 2) {  // fade out
    float pct = phaseFrame / float(fadeDuration);
    blurLevel = lerp(0, blurAmount, pct);
    alpha = lerp(255, 0, pct);
  }

  PImage blurred = getBlurred(currentImg, blurLevel);
  tint(255, alpha);
  imageMode(CENTER);
  image(blurred, width / 2, height / 2);
  noTint();

  saveFrame("frames/frame-####.png");

  phaseFrame++;
  if ((phase == 0 || phase == 2) && phaseFrame >= fadeDuration) {
    phase++;
    phaseFrame = 0;
  } else if (phase == 1 && phaseFrame >= holdDuration) {
    phase++;
    phaseFrame = 0;
  }

  if (phase > 2) {
    imgIndex++;
    if (imgIndex >= totalImages) {
      done = true;
    } else {
      loadNextImage();
    }
  }
}

void loadNextImage() {
  currentImg = images[imgIndex];
  float imgRatio = currentImg.width / float(currentImg.height);
float canvasRatio = width / float(height);

int newW, newH;
if (imgRatio > canvasRatio) {
  newW = width;
  newH = int(width / imgRatio);
} else {
  newH = height;
  newW = int(height * imgRatio);
}
currentImg.resize(newW, newH);

  phase = 0;
  phaseFrame = 0;
}

PImage getBlurred(PImage img, float amount) {
  PGraphics pg = createGraphics(img.width, img.height);
  pg.beginDraw();
  pg.image(img, 0, 0);
  pg.filter(BLUR, amount);
  pg.endDraw();
  return pg.get();
}
