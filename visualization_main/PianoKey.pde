/*

 Created by:
 Jack
 On Date:
 5-Jul-2021
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
  boolean split = false; // whether key should be split for visualization

  PianoKey(int nId, float xpos, float ypos, float inWidth, float inHeight) {
    id = nId;
    x = xpos;
    y = ypos;
    keyWidth = inWidth;
    keyHeight = inHeight;
  }

  void setInProb(float newProb) {
    // setter for in probability
    assert newProb <= 1;
    this.inProb = newProb;
  }

  void setOutProb(float newProb) {
    // setter for out probability
    assert newProb <= 1;
    this.outProb = newProb;
  }

  float getInProb() {
    // getter for in probability
    return this.inProb;
  }

  float getOutProb() {
    // getter for out probability
    return this.outProb;
  }
  
  float getTotalProb() {
    // getter for total
    return this.inProb + this.outProb;
  }

  void drawKey() {
    // function to draw a piano key
    this.split = false;
    float[] colArray = getProbColor(); // heat map just for user input?
    fill(colArray[0], colArray[1], colArray[2]); // fill RGB values
    rect(x, y, keyWidth, keyHeight);
    
    if (this.split) {
      // overlay split key in blue
      colArray = toRGB(230, 100, 100 - ((getLume(this.inProb)*55) + 20), 1.0f);
      fill(colArray[0], colArray[1], colArray[2]);
      triangle(x, y, x + keyWidth, y, x, y + keyHeight);
    }
  }

  // function to retrieve color to set key to
  float[] getProbColor() {
    float[] cols = toRGB(0, 100, 100, 1); // white
    if (this.inProb > 0 && this.outProb == 0) {
      // pure user input, blue color
      cols = toRGB(230, 100, 100 - ((getLume(this.inProb)*55) + 20), 1.0f);
    } else if (this.outProb > 0 && this.inProb == 0) {
      // pure system input, orange color
      cols = toRGB(39, 100, 100 - ((getLume(this.outProb)*55) + 20), 1.0f);
    } else if (this.inProb > 0 && this.outProb > 0) {
      // both system and user input
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
          cols = new float[] {204, 204, 204}; // slightly darker
        }
      }      
    }

    return cols;
  }
}
