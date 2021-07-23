/*

 Created by:
 Jack
 On Date:
 5-Jul-2021
 Purpose & intent:
 * act as class for full-size keyboard
 */

/**
 * Class that represents a keyboard, made up of individual piano keys.
 * @see PianoKey
 */
class Keyboard {
  // setting constants
  float PIANO_WIDTH = width-(height/8); // 
  float PIANO_HEIGHT = 2*height/6; // 2/6 down the page
  boolean numbersOn = false;

  // deriving widths
  float whiteWidth = PIANO_WIDTH/52; // 52 white keys
  float whiteHeight = 2*height/8; // 2/8 of screen Y
  float blackWidth = 2*whiteWidth/3; // 2/3 of white key X
  float blackHeight = 2*whiteHeight/3; // 2/3 of white key Y

  // 88 keys; midi numbers range from 21–108
  PianoKey[] keyArray = new PianoKey[88];
  int[] whiteKeys = {0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24, 26, 27, 29, 31, 32, 34, 36, 38, 39, 41, 43, 44, 46, 48, 50, 51, 53, 55, 56, 58, 60, 62, 63, 65, 67, 68, 70, 72, 74, 75, 77, 79, 80, 82, 84, 86, 87};
  int[] blackKeys = {1, 4, 6, 9, 11, 13, 16, 18, 21, 23, 25, 28, 30, 33, 35, 37, 40, 42, 45, 47, 49, 52, 54, 57, 59, 61, 64, 66, 69, 71, 73, 76, 78, 81, 83, 85};

  Keyboard() {
  }

  void addKeys() {
    // function to add keys to piano
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
      if (keyId == 4 || (keyId-3)%12 == 6 || (keyId-3)%12 == 1) {
        offset += whiteWidth; // extra spaces between black keys
      }
      PianoKey newKey = new PianoKey(keyId, (2*whiteWidth - blackWidth)/2 + offset, PIANO_HEIGHT, blackWidth, blackHeight);
      keyArray[keyId] = newKey; // add key to key array
      offset += whiteWidth;
    }
  }

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
      // display graphics
      displayGraphic();
    } else {
      // showing moving average
      stroke(0, 0, 205);
      strokeWeight(15);
      float p_len = PIANO_WIDTH/89; // normalize to scale
      point((width-PIANO_WIDTH)/2 + (inAvg*p_len), PIANO_HEIGHT + 1.1*whiteHeight); // scale, place beneath keyboard
      stroke(255, 140, 0);
      point((width-PIANO_WIDTH)/2 + (outAvg*p_len), PIANO_HEIGHT + 1.1*whiteHeight); // scale, place beneath keyboard
      strokeWeight(1);
      stroke(0);
    }
  }

  void displayGraphic() {
    // handles graph vis.
    int totalVis = 3;
    GPointsArray points = new GPointsArray(88); // maybe don't need to redefine these
    GPointsArray pointsOut = new GPointsArray(88);

    // user input
    float maxPoint = 0.0;
    // updating graph
    for (int i=0; i < 88; i++) {
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

    // show correct graph
    switch (vis % totalVis) {
    case 0: // double line
      plot.setPoints(points);
      plot.removeLayer("layer 1");
      plot.addLayer("layer 1", pointsOut);
      plot.getLayer("layer 1").setLineColor(color(255, 206, 162)); // orange = system

      // Draw the plot
      plot.beginDraw();
      plot.setYLim(0, maxPoint); // set Y-axis max to max point
      //plot.drawBackground();
      plot.drawYAxis();
      //plot.drawXAxis(); // for testing
      //plot.drawGridLines(GPlot.BOTH);
      //plot.drawLines();
      plot.drawFilledContours(GPlot.HORIZONTAL, 0);
      //plot.getLayer("layer 1").drawFilledContour(GPlot.HORIZONTAL, 0);
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

  void toggleNumbers() {
    numbersOn = !numbersOn;
  }

  void updateInFreqs(int[] freq) {
    // updates user frequencies for keys across keyboard given most recent OSC message
    assert freq.length == keyArray.length;
    inAvg = 0.0;

    for (int i=0; i<keyArray.length; i++) {
      if (post) {
        // do not normalize by notesStored if post analysis triggered
        keyArray[i].setInProb((((float) freq[i])/histIn.split("-").length)/2);
        inAvg += i*((float) freq[i])/histIn.split("-").length;
      } else {
        keyArray[i].setInProb((((float) freq[i])/notesStored)/2); // normalize to get 'empirical probability' distribution
        inAvg += i*((float) freq[i])/notesStored;
      }
    }
  }

  void updateOutFreqs(int[] freq) {
    // updates system frequencies for keys across keyboard given most recent OSC message
    assert freq.length == keyArray.length;
    outAvg = 0.0;

    for (int i=0; i<keyArray.length; i++) {
      if (post) {
        // do not normalize by notesStored
        keyArray[i].setOutProb((((float) freq[i])/histOut.split("-").length)/2);
        outAvg += i*(((float) freq[i])/histOut.split("-").length);
      } else {
        keyArray[i].setOutProb((((float) freq[i])/notesStored)/2); // normalize to get 'empirical probability' distribution
        outAvg += i*(((float) freq[i])/notesStored);
      }
    }
  }

  void displayLabels() {
    // function to display labels beneath white keys, above black

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

      if (i == 1 || (i-1)%5 == 0 || (i-1)%5 == 2) {
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
