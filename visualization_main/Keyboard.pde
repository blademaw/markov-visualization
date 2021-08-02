/*

 Created by:
 Jack
 On Date:
 5-Jul-2021
 Last updated on:
 02-Aug-2021
 Purpose & intent:
 * act as class for full-size keyboard
 */

/**
 * Class that represents a keyboard, made up of individual piano keys.
 * @see PianoKey
 */
class Keyboard {
  // setting constants
  float PIANO_WIDTH = width-(height/8);
  float PIANO_HEIGHT = 2*height/6;
  boolean numbersOn = false;

  // deriving widths
  float whiteWidth = PIANO_WIDTH/36; // 36 available white keys
  float whiteHeight = 2*height/8; // 2/8 of screen Y
  float blackWidth = 2*whiteWidth/3; // 2/3 of white key X
  float blackHeight = 2*whiteHeight/3; // 2/3 of white key Y

  // 61 keys; midi numbers range from 36–96
  PianoKey[] keyArray = new PianoKey[88];
  int[] whiteKeys = {15, 17, 19, 20, 22, 24, 26, 27, 29, 31, 32, 34, 36, 38, 39, 41, 43, 44, 46, 48, 50, 51, 53, 55, 56, 58, 60, 62, 63, 65, 67, 68, 70, 72, 74, 75};
  int[] blackKeys = {16, 18, 21, 23, 25, 28, 30, 33, 35, 37, 40, 42, 45, 47, 49, 52, 54, 57, 59, 61, 64, 66, 69, 71, 73};

  Keyboard() {
  }

  /**
   * Function to add keys to piano
   */
  void addKeys() {
    // initializing white keys
    float offset = 0.0;
    for (int keyId : whiteKeys) {
      PianoKey newKey = new PianoKey(keyId, (width-PIANO_WIDTH)/2 + offset, PIANO_HEIGHT, whiteWidth, whiteHeight);
      keyArray[keyId] = newKey; // add key to key array
      offset += whiteWidth;
    }

    // initializing black keys
    offset = (width-PIANO_WIDTH)/2; // begin at first white key
    for (int keyId : blackKeys) {
      if ((keyId-15)%12  == 6 || (keyId-15)%12 == 1 && keyId != 16) {
        offset += whiteWidth; // extra spaces between black keys
      }
      // position key in the middle of this white key and the next one
      PianoKey newKey = new PianoKey(keyId, (2*whiteWidth - blackWidth)/2 + offset, PIANO_HEIGHT, blackWidth, blackHeight);
      keyArray[keyId] = newKey; // add key to key array
      offset += whiteWidth;
    }
  }

  /**
   * Displays piano keys on screen
   */
  void display() {    
    // displays keys, handling overlap order
    for (int pKey : whiteKeys) {
      keyArray[pKey].drawKey(); // drawing white keys
    }

    for (int pKey : blackKeys) {
      keyArray[pKey].drawKey(); // drawing black keys over
    }

    if (numbersOn && !graphVis) {
      displayLabels(); // displaying freq labels if desired
    }

    if (graphVis) {
      // display graph visualisations
      displayGraphic();
    } else {
      if (disMovAvg) {
        // showing moving average
        stroke(0, 0, 205);
        strokeWeight(15);
        float p_len = PIANO_WIDTH/61; // normalize to scale
        point((width-PIANO_WIDTH)/2 + ((inAvg)*p_len), PIANO_HEIGHT + 1.1*whiteHeight); // scale, place beneath keyboard
        stroke(255, 140, 0);
        point((width-PIANO_WIDTH)/2 + ((outAvg)*p_len), PIANO_HEIGHT + 1.1*whiteHeight); // scale, place beneath keyboard
        strokeWeight(1);
        stroke(0);
      }
    }
  }

  /**
   * Function to display line/histogram visualisations
   */
  void displayGraphic() {
    int totalVis = 3;
    GPointsArray points = new GPointsArray(61);
    GPointsArray pointsOut = new GPointsArray(61);

    // user input
    float maxPoint = 0.0;
    // updating graph
    for (int i=15; i < 76; i++) { // 61 key array 
      float thisInFreq = keyArray[i].getInProb();
      float thisOutFreq = keyArray[i].getOutProb();

      points.add(i, thisInFreq); // add each key
      pointsOut.add(i, thisOutFreq);
      // adjust for max Y axis
      if (thisInFreq > maxPoint) {
        maxPoint = thisInFreq;
      } else if (thisOutFreq > maxPoint) {
        maxPoint = thisOutFreq;
      }
    }

    // show selected graph
    switch (vis % totalVis) {
    case 0: // double line
      plot.setPoints(points);
      plot.removeLayer("layer 1");
      plot.addLayer("layer 1", pointsOut);
      plot.getLayer("layer 1").setLineColor(color(255, 206, 162)); // orange = system

      // Draw the plot
      plot.beginDraw();
      plot.setYLim(0, maxPoint); // set Y-axis max to max point
      plot.drawYAxis();
      plot.drawFilledContours(GPlot.HORIZONTAL, 0);
      plot.endDraw();
      break;

    case 1:
      plot.setPoints(points);
      plot.setLineColor(color(178, 206, 252));
      plot.removeLayer("layer 1");
      plot.addLayer("layer 1", pointsOut);
      plot.getLayer("layer 1").setLineWidth(3.0);
      plot.getLayer("layer 1").setLineColor(color(255, 206, 162)); // orange = system

      // Draw the plot
      plot.beginDraw();
      plot.setYLim(0, maxPoint); // set Y-axis max to max point
      plot.drawYAxis();
      plot.setLineWidth(3.0);
      plot.drawLines();
      plot.endDraw();
      break;

    case 2:
      plot.setPoints(points);
      plot1.setPoints(pointsOut);

      // Draw the plots
      plot.beginDraw();
      plot.setYLim(0, maxPoint); // set Y-axis max to max point
      plot.drawYAxis();
      plot.drawHistograms();
      plot.endDraw();

      plot1.beginDraw();
      plot1.getHistogram().setBgColors(new color[] {color(255, 206, 162) });
      plot1.setYLim(0, maxPoint);
      plot1.drawYAxis();
      //plot1.getHistogram().setDrawLabels(true);
      plot1.drawHistograms();
      plot1.endDraw();

      break;
    }
  }

  /**
   * Function to toggle normalised frequency labels
   */
  void toggleNumbers(boolean status) {
    if (status) {
      numbersOn = true;
    } else { 
      numbersOn = false;
    }
  }

  /**
   * Function to update input probabilities/normalised frequencies of keys based on frequency array
   */
  void updateInFreqs(int[] freq) {
    assert freq.length == keyArray.length;
    inAvg = 0.0;

    for (int i=15; i<76; i++) {
      if (post) {
        // do not normalize by notesStored if post analysis triggered
        keyArray[i].setInProb((((float) freq[i])/histIn.split("-").length)/2);
        inAvg += (i-15)*((float) freq[i])/histIn.split("-").length;
      } else {
        keyArray[i].setInProb((((float) freq[i])/notesStored)/2); // normalize to get 'empirical probability' distribution
        inAvg += (i-15)*((float) freq[i])/notesStored;
      }
    }
  }

  /**
   * Function to update output probabilities/normalised frequencies of keys based on frequency array
   */
  void updateOutFreqs(int[] freq) {
    assert freq.length == keyArray.length;
    outAvg = 0.0;

    for (int i=15; i<76; i++) {
      if (post) {
        // do not normalize by notesStored
        keyArray[i].setOutProb((((float) freq[i])/histOut.split("-").length)/2);
        outAvg += (i-15)*(((float) freq[i])/histOut.split("-").length);
      } else {
        keyArray[i].setOutProb((((float) freq[i])/notesStored)/2); // normalize to get 'empirical probability' distribution
        outAvg += (i-15)*(((float) freq[i])/notesStored);
      }
    }
  }

  /**
   * Function to display rotated normalised frequency labels if desired
   */
  void displayLabels() {
    // white keys
    textFont(f, (width+height)/100);
    fill(0);

    float offset = (width-PIANO_WIDTH)/2; // start where piano starts
    for (int pKey : whiteKeys) {
      pushMatrix();
      translate(offset + whiteWidth/4, PIANO_HEIGHT + 1.15*whiteHeight);
      rotate(PI/2);
      text(keyArray[pKey].getTotalProb(), 0, 0);
      popMatrix();
      offset += whiteWidth;
    }

    // black keys
    offset = (width-PIANO_WIDTH)/2; // start where piano starts
    textFont(f, .9*((width+height)/100));
    for (int i=0; i<blackKeys.length; i++) {
      PianoKey pKey = keyArray[blackKeys[i]];

      pushMatrix();

      if (i%5 == 2 || i%5 == 0 && i != 0) {
        offset += whiteWidth; // ensure correct position of 3rd black key
      }

      translate(offset + (whiteWidth - blackWidth/2) + blackWidth/12, PIANO_HEIGHT + 1.5*whiteHeight);
      rotate(PI/2);
      text(pKey.getTotalProb(), 0, 0);
      popMatrix();
      offset += whiteWidth;
    }
  }
}
