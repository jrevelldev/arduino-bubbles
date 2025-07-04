import java.io.File;
import java.util.Collections;
import java.util.Arrays;
import java.util.List;

String[] imagePaths;
int imgIndex = 0;
PImage currentImg;

int phase = 0;  // 0 = fade in, 1 = hold, 2 = fade out
int phaseFrame = 0;
int fps = 25;

float fadeTimeSec = 2.0;
float holdTimeSec = 5.0;

int fadeDuration = int(fadeTimeSec * fps);
int holdDuration = int(holdTimeSec * fps);

float blurAmount = 20;
boolean done = false;

String saveFramePattern = "frames/frame-####.png";  // will be updated dynamically

public void settings() {
  size(500, int(500 * 1633.0 / 2177.0));  // preserve aspect ratio
}

void setup() {
  frameRate(fps);

  // Clear previous frames
  File framesDir = new File(sketchPath("frames"));
  if (framesDir.exists()) {
    for (File f : framesDir.listFiles()) {
      if (f.isFile() && f.getName().endsWith(".png")) {
        f.delete();
      }
    }
  } else {
    framesDir.mkdirs();
  }

  // Get image file paths
  ArrayList<String> tempList = new ArrayList<String>();
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
          tempList.add(folder + "/" + f.getName());
        }
      }
    }
  }

  imagePaths = tempList.toArray(new String[0]);

  // Shuffle
  List<String> pathList = Arrays.asList(imagePaths);
  Collections.shuffle(pathList);
  imagePaths = pathList.toArray(new String[0]);

  if (imagePaths.length == 0) {
    println("❌ No images found.");
    exit();
  }

  // Estimate total frames
  int framesPerImage = fadeDuration * 2 + holdDuration;
  int totalFrames = framesPerImage * imagePaths.length;
  float estimatedSeconds = totalFrames / float(fps);
  float estimatedMinutes = estimatedSeconds / 60.0;

  println("🖼️  Total images to process: " + imagePaths.length);
  println("🎞️  Total frames to output: " + totalFrames);
  println("⏱️  Estimated render time at " + fps + " fps: " +
         nf(estimatedSeconds, 0, 1) + " sec (" +
         nf(estimatedMinutes, 0, 1) + " min)");

  // Create dynamic frame pattern based on totalFrames
  int digitCount = str(totalFrames).length();  // e.g. "47000" → 5
  String hashPattern = "";
  for (int i = 0; i < digitCount; i++) {
    hashPattern += "#";
  }
  saveFramePattern = "frames/frame-" + hashPattern + ".png";

  // Write render-info.txt
  String info = "Render Info\n"
              + "===========\n"
              + "Resolution: " + width + " x " + height + "\n"
              + "Framerate: " + fps + " fps\n"
              + "Fade Duration: " + fadeTimeSec + " sec\n"
              + "Hold Duration: " + holdTimeSec + " sec\n"
              + "Frames per Image: " + framesPerImage + "\n"
              + "Total Images: " + imagePaths.length + "\n"
              + "Total Frames: " + totalFrames + "\n"
              + "Save Pattern: " + saveFramePattern + "\n";

  saveStrings("render-info.txt", split(info, "\n"));

  loadNextImage();
}

void draw() {
  if (done) {
    println("✅ All images processed.");
    exit();
    return;
  }

  background(0);

  float alpha = 255;
  float blurLevel = 0;

  if (phase == 0) {
    float pct = phaseFrame / float(fadeDuration);
    blurLevel = lerp(blurAmount, 0, pct);
    alpha = lerp(0, 255, pct);
  } else if (phase == 1) {
    blurLevel = 0;
    alpha = 255;
  } else if (phase == 2) {
    float pct = phaseFrame / float(fadeDuration);
    blurLevel = lerp(0, blurAmount, pct);
    alpha = lerp(255, 0, pct);
  }

  PImage blurred = getBlurred(currentImg, blurLevel);
  tint(255, alpha);
  imageMode(CENTER);
  image(blurred, width / 2, height / 2);
  noTint();

  saveFrame(saveFramePattern);  // uses dynamic ###### format

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
    if (imgIndex >= imagePaths.length) {
      done = true;
    } else {
      loadNextImage();
    }
  }
}

void loadNextImage() {
  println("📷 Rendering image " + (imgIndex + 1) + " of " + imagePaths.length);
  currentImg = loadImage(imagePaths[imgIndex]);

  // Resize with aspect ratio
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
