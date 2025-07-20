import java.util.Collections;

ArrayList<String> imageFilenames = new ArrayList<String>();
ArrayList<Integer> order = new ArrayList<Integer>();
int currentIndex = 0;
PImage currentImage;

////////////////////////
void loadImages() {
  imageFilenames.clear();
  File folder = new File(dataPath(""));
  File[] files = folder.listFiles();

  if (files == null) {
    println("⚠️ No image files found.");
    return;
  }

  for (File file : files) {
    String name = file.getName().toLowerCase();
    if (name.endsWith(".png") || name.endsWith(".jpg")) {
      imageFilenames.add(file.getName());
    }
  }

  println("📷 " + imageFilenames.size() + " image filenames loaded.");
}


////////////////////////
void shuffleOrder() {
  order.clear();
  for (int i = 0; i < imageFilenames.size(); i++) {
    order.add(i);
  }
  Collections.shuffle(order);
  currentIndex = 0;
}

////////////////////////
void loadNextImage() {
  if (imageFilenames.size() == 0) return;

  if (currentImage != null) {
    currentImage = null; // release previous image
    System.gc(); // optional, helps memory cleanup
  }

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
}

//////////HELPERS//////////////
PImage scaleToFit(PImage img, int maxW, int maxH) {
  float ratio = min(maxW / (float)img.width, maxH / (float)img.height);
  int newW = int(img.width * ratio);
  int newH = int(img.height * ratio);
  img.resize(newW, newH);
  return img;
}
