/*

 Created by:
 Jack
 On Date:
 5-Jul-2021
 Last updated on:
 23-Jul-2021
 Purpose & intent:
 * act as class for individual piano key
 */

/**
 * Class that represents an individual key on a piano.
 * Used in conjunction with Keyboard to represent full piano
 * @see Keyboard
 */
class PianoKey {
  int id; // unique ID of key
  float x; // x position
  float y; // y position
  float inProb = 0.0; // empirical probability of user playing key
  float outProb = 0.0; // empirical probability of computer playing key
  float keyWidth; // width of key
  float keyHeight; // height of key
  boolean split = false; // whether _this key_ should be split

  PianoKey(int nId, float xpos, float ypos, float inWidth, float inHeight) {
    id = nId;
    x = xpos;
    y = ypos;
    keyWidth = inWidth;
    keyHeight = inHeight;
  }

  /**
   * Sets input normalised frequency of piano key
   */
  void setInProb(float newProb) {
    // setter for in probability
    assert newProb <= 1;
    this.inProb = newProb;
  }

  /**
   * Sets output normalised frequency of piano key
   */
  void setOutProb(float newProb) {
    // setter for out probability
    assert newProb <= 1;
    this.outProb = newProb;
  }

  /**
   * Gets input normalised frequency of piano key
   */
  float getInProb() {
    // getter for in probability
    return this.inProb;
  }

  /**
   * Gets output normalised frequency of piano key
   */
  float getOutProb() {
    // getter for out probability
    return this.outProb;
  }

  /**
   * Gets combined normalised frequency of piano key
   */
  float getTotalProb() {
    // getter for total
    return this.inProb + this.outProb;
  }

  /**
   * Draws a specific key on the screen
   */
  void drawKey() {
    this.split = false;
    float[] colArray = getProbColor(); // get colour gradient
    fill(colArray[0], colArray[1], colArray[2]);
    float dispX, dispY, dispKeyH;

    // adjusting dimensions of key if graph mode is on
    if (graphVis) {
      dispX = x;
      dispY = 10.5*height/20;
      dispKeyH = 2*keyHeight/3;
    } else {
      dispX = x;
      dispY = y;
      dispKeyH = keyHeight;
    }
    rect(dispX, dispY, keyWidth, dispKeyH);

    if (this.split) {
      // overlay split key in blue
      colArray = toRGB(230, 100, 100 - ((getLume(this.inProb)*55) + 20), 1.0f);
      fill(colArray[0], colArray[1], colArray[2]);
      triangle(dispX, dispY, dispX + keyWidth, dispY, dispX, dispY + dispKeyH);
    }
  }

  /**
   * Function to retrieve colour of key from gradient(s)
   */
  float[] getProbColor() {
    float[] cols = toRGB(0, 100, 100, 1); // white    
    if (this.inProb > 0 && this.outProb == 0) {
      // pure user input, blue color
      cols = toRGB(230, 100, 100 - ((getLume(this.inProb)*55) + 20), 1.0f);
    } else if (this.outProb > 0 && this.inProb == 0) {
      // pure system input, orange color
      cols = toRGB(39, 100, 100 - ((getLume(this.outProb)*55) + 20), 1.0f);
    } else if (this.inProb > 0 && this.outProb > 0) {
      // both system and user input, either split or combine
      if (splitKey) {
        cols = toRGB(39, 100, 100 - ((getLume(this.outProb)*55) + 20), 1.0f); // color rect orange, triangle blue
        this.split = true;
      } else {
        cols = toRGB(0, 100, 100 - ((getLume(this.inProb + this.outProb)*55) + 20), 1.0f); // total as one key
      }
    } else {
      cols = new float[] {255, 255, 255}; // default color
      for (int bKey : keyboard.blackKeys) {
        if (id == bKey) {
          cols = new float[] {204, 204, 204}; // slightly darker for black keys
        }
      }
    }

    return cols;
  }
}
