/**
 * Image Fade-In/Fade-Out Video Frame Generator
 * =============================================
 * 
 * Description:
 * ------------
 * This Processing sketch generates a sequence of images with smooth transitions 
 * (fade-in, hold, fade-out) between them. Each image is blurred at the start 
 * and end, and sharp during the hold phase. All frames are saved to a "frames/" 
 * folder and can be compiled into a video externally.
 * 
 * Output:
 * -------
 * - Frames saved as PNGs using a dynamic filename pattern like `frames/frame-000001.png`.
 * - Metadata file `render-info.txt` saved in the sketch directory.
 * 
 * Preconfiguration Required:
 * --------------------------
 * 1. Place your input images inside the following folders (relative to the sketch's data folder):
 *    - `images/folder1`
 *    - `images/folder2`
 *    - `images/folder3`
 *    - `images/folder4`
 *    You can customize or extend this list in the `folders` array in `setup()`.
 * 
 * 2. Ensure each folder contains images named with `.jpg` or `.png` extensions.
 * 3. Make sure the "frames" directory is writable (the script will create or clear it).
 * 
 * Timing Settings:
 * ----------------
 * - Fade-in duration: 2 seconds
 * - Hold duration: 5 seconds
 * - Fade-out duration: 2 seconds
 * - Frame rate: 25 FPS
 * 
 * Other Notes:
 * ------------
 * - Images are automatically resized to fit a canvas of width 500px, preserving aspect ratio.
 * - The sketch estimates and prints the total frame count and rendering time.
 * - All image paths are shuffled to ensure a random order of display.
 * - Once rendering is complete, the sketch exits automatically.
 * 
 * Useful for:
 * -----------
 * - Creating smooth video loops or transitions from still images.
 * - Generating time-synced frame sequences for music videos, installations, or generative art.
 */


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

String saveFramePattern = "frames/frame-####.png";
int savedFrameCount = 0;
int digitCount;
long startTime;

public void settings() {
  size(500, int(500 * 1633.0 / 2177.0));  // preserve aspect ratio
}

void setup() {
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
  List<String> pathList = Arrays.asList(imagePaths);
  Collections.shuffle(pathList);
  imagePaths = pathList.toArray(new String[0]);

  if (imagePaths.length == 0) {
    println("❌ No images found.");
    exit();
  }

  int framesPerImage = fadeDuration * 2 + holdDuration;
  int totalFrames = framesPerImage * imagePaths.length;
  float estimatedSeconds = totalFrames / float(fps);
  float estimatedMinutes = estimatedSeconds / 60.0;
  digitCount = str(totalFrames).length();

  println("🖼️  Total images to process: " + imagePaths.length);
  println("🎞️  Total frames to output: " + totalFrames);
  println("⏱️  Estimated render time at " + fps + " fps: " +
         nf(estimatedSeconds, 0, 1) + " sec (" +
         nf(estimatedMinutes, 0, 1) + " min)");

  saveFramePattern = "frames/frame-" + repeat("#", digitCount) + ".png";

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

  startTime = millis();

  while (!done) {
    renderFrame();
    redraw();   // force canvas update
    delay(1);   // allow time for repaint
  }

  long totalTime = millis() - startTime;
  println("✅ Done: rendered " + savedFrameCount + " frames in " + (totalTime / 1000.0) + " seconds.");
  delay(500);
  exit();
}

void renderFrame() {
  float alpha = 255;
  float blurLevel = 0;
  float pct = 0;

  if (phase == 0) {
    pct = phaseFrame / (float)fadeDuration;
    blurLevel = lerp(blurAmount, 0, pct);
    alpha = lerp(0, 255, pct);
  } else if (phase == 1) {
    blurLevel = 0;
    alpha = 255;
  } else if (phase == 2) {
    pct = phaseFrame / (float)fadeDuration;
    blurLevel = lerp(0, blurAmount, pct);
    alpha = lerp(255, 0, pct);
  }

  // Prepare blurred frame
  PImage blurred = getBlurred(currentImg, blurLevel);

  // ✅ Draw to window
  surface.setTitle("Rendering frame " + savedFrameCount);
  background(0);
  tint(255, alpha);
  imageMode(CENTER);
  image(blurred, width / 2, height / 2);
  noTint();

  // ✅ Save to disk
  String filename = "frames/frame-" + nf(savedFrameCount, digitCount) + ".png";
  saveFrame(filename);
  savedFrameCount++;

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


// Optional: Preview mode (doesn't save frames)
void draw() {
  if (!done) return;

  background(0);
  tint(255);
  imageMode(CENTER);
  image(currentImg, width / 2, height / 2);
  noTint();
}

// Load and resize the next image
void loadNextImage() {
  println("📷 Rendering image " + (imgIndex + 1) + " of " + imagePaths.length);
  currentImg = loadImage(imagePaths[imgIndex]);

  float imgRatio = currentImg.width / (float)currentImg.height;
  float canvasRatio = width / (float)height;
  int newW, newH;

  if (imgRatio > canvasRatio) {
    newW = width;
    newH = (int)(width / imgRatio);
  } else {
    newH = height;
    newW = (int)(height * imgRatio);
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

// Simple utility to repeat a character
String repeat(String c, int count) {
  String result = "";
  for (int i = 0; i < count; i++) result += c;
  return result;
}
