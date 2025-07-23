import java.util.Collections;

ArrayList<String> imageFilenames = new ArrayList<String>();
ArrayList<Integer> order = new ArrayList<Integer>();

ArrayList<PImage> images = new ArrayList<PImage>();
int currentIndex = 0;

PImage currentImage;
PImage currentBlurred;


////////////////////////
void loadImages() {
  File folder = new File(dataPath(""));
  File[] files = folder.listFiles();
  if (files == null) return;

  for (File file : files) {
    if (file.getName().toLowerCase().endsWith(".png")) {
      PImage img = loadImage(file.getName());
      if (img != null) {
        img.resize(800, 800);  // scale to fit 800x800 box
        images.add(img);
      }
    }
  }
}


////////////////////////
void shuffleOrder() {
  order.clear();
  for (int i = 0; i < images.size(); i++) {
    order.add(i);
  }
  Collections.shuffle(order);
}

////////////////////////
void loadNextImage() {
  if (order.size() == 0) shuffleOrder();
  int index = order.remove(0);
  currentImage = images.get(index);

  // Pre-blur version
  sharpImage = currentImage;
  blurredImage = getBlurredVersion(currentImage, maxBlur);
}
////////////////////
PImage getBlurredVersion(PImage img, float blurAmt) {
  if (img == null) return null;
  blurAmt = constrain(blurAmt, 0, 10); // You can adjust max blur here if needed

  PGraphics pg = createGraphics(img.width, img.height);
  pg.beginDraw();
  pg.image(img, 0, 0);
  pg.filter(BLUR, blurAmt);
  pg.endDraw();

  return pg.get();
}

/*
  String nextFile = imageFilenames.get(order.get(currentIndex));
  PImage loaded = loadImage(nextFile);

  if (loaded != null) {
    currentImage = scaleToFit(loaded, 800, 800);
  }

  currentIndex++;
  if (currentIndex >= imageFilenames.size()) {
    shuffleOrder(); // restart with shuffled order
  }

  phase = 0;
  phaseStartTime = millis();
}*/

//////////HELPERS//////////////
PImage scaleToFit(PImage img, int maxW, int maxH) {
  float ratio = min(maxW / (float)img.width, maxH / (float)img.height);
  int newW = int(img.width * ratio);
  int newH = int(img.height * ratio);
  img.resize(newW, newH);
  return img;
}
