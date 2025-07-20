/*
  Image Viewer with ESP32 Distance-Controlled Transitions (with Simulation Fallback)
  -----------------------------------------------------------------------------------

  Overview:
  ---------
  This Processing sketch displays a sequence of images that fade in and out,
  controlled by a distance sensor connected via WiFi (ESP32). It also supports 
  a simulation mode, which can be activated manually if no hardware is available.

  Images are loaded from the "data" folder and are shown in randomized, non-repeating 
  order. After all images have been displayed once, the cycle reshuffles and starts again.

  Features:
  ---------
  - Intro Screen:
      Shows instructions for connecting to ESP32 via WiFi.
      Press 'S' during this screen to activate simulation mode.
  
  - Sensor Reading:
      - Attempts to read from "http://192.168.10.1/data"
      - If unreachable and simulation is not enabled, no data is returned.
      - Simulation mode mimics a smooth cyclic transition between 0 and 200 cm,
        with a 5–10 second pause at each end.

  - Image Display:
      - Images fade in over 2 seconds, hold for 5 seconds, and fade out over 2 seconds.
      - Images are randomly selected and non-repeating within a cycle.
      - After all images have been shown, the order reshuffles.
      - Images are scaled to fit within an 800x800 box while maintaining aspect ratio.

  - UI Info Overlay:
      - Displays the current distance (real or simulated) in the top-right corner.
      - Indicates when simulation mode is active.

  File Structure:
  ---------------
  - Main.pde            : UI, draw loop, transitions, and image display
  - SensorReader.pde    : Handles real and simulated distance data
  - ImageManager.pde    : Loads images and manages random order logic
  - data/               : Folder containing images (e.g., image1.png, image2.png, etc.)

  Notes:
  ------
  Simulation mode is essential for development and testing without needing an ESP32.
  Use the 'S' key at startup to activate it.
*/
