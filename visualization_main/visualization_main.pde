/**
 Created by:
 Jack
 On date:
 14-Jul-2021
 Last updated on:
 22-Jul-2021
 Purpose:
 experiment further with Markov system visualizations
 */

import java.util.*;
import java.awt.Color;
import oscP5.*;
import netP5.*;
import grafica.*;
import themidibus.*;

Keyboard keyboard;
OscP5 oscRec; 
PFont f;
int notesStored, lastNotes, ARR_SIZE, intervalTime, prevTime, secNotes, vis;
float inAvg, outAvg; // average notes/sec human, and system
boolean post, splitKey, midiRec, graphVis;
String histIn, histOut, keySig;
String[] lastArray, lastOutArray;
String[] noteToText = {"C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G", "G#/Ab", "A", "A#/Bb", "B"};
Queue queue = new Queue(30); // averaging notes per second over every 30 last received chunks/seconds
MidiBus inBus, outBus; // two MidiBusses for receiving input from user and output from system
GPlot plot, plot1; // two plots (hist, line)
GPointsArray points, pointsOut;

void setup() {
  size(1000, 600); // TODO: make this adaptable to any screen size
  strokeWeight(1);
  f = createFont("Arial", 16, true);

  // initialize virtual piano
  keyboard = new Keyboard();
  keyboard.addKeys();

  // setting up OSC receiving
  OscProperties op = new OscProperties();
  op.setListeningPort(9001);
  op.setDatagramSize(150000); // sets maximum message length — need this or else UdpServer throws an error
  // 126,000 characters needed for 60 minutes of input, 10 notes per second, with 3.5 average character length of string
  oscRec = new OscP5(this, op);
  oscRec.plug(this, "inputReceive", "/InputMemory"); // plugging the two current note OSC messages
  oscRec.plug(this, "outputReceive", "/OutputMemory");

  // setting up MidiBus & midi values
  inBus = new MidiBus(this, 1, 0, "input"); // currently takes fixed VMPK output
  outBus = new MidiBus(this, 0, 0, "output"); // currently takes fixed Bus 1 output
  intervalTime = 1000; // recieve notes per _second_
  prevTime = 0;
  secNotes = 0; // number of notes recieved in past second

  // setting up graph visualizations
  int nPoints = 88; // 88 keys
  points = new GPointsArray(nPoints);
  pointsOut = new GPointsArray(nPoints);
  plot = new GPlot(this);

  // dimensions
  float graphX = -width*.12;
  float graphYMax = height/20;
  float graphWidth = width*1.1;
  float graphHeight = 8*height/20;

  plot.setPos(graphX, graphYMax); // top-left corner
  plot.setYLim(0, 1); // max 1 normalized frequency
  plot.setDim(graphWidth, graphHeight);
  plot.setLineColor(color(178, 206, 252));
  plot.addLayer("layer 1", pointsOut);
  plot.startHistograms(GPlot.VERTICAL);
  //plot.getLayer("layer 1").setLineColor(color(255, 206, 162));
  //plot.getYAxis().setAxisLabelText("probability");

  // second line for system input
  plot1 = new GPlot(this);
  plot1.setPos(graphX, graphYMax);
  plot1.setYLim(0, 1);
  plot1.setDim(graphWidth, graphHeight);
  plot1.setLineColor(color(255, 206, 162));
  plot1.startHistograms(GPlot.VERTICAL);

  // setting initial global variables
  post = false; // toggle post analysis
  lastNotes = 0; // notes recieved last OSC tick
  notesStored = 40; // notes to create ongoing/real-time visualization
  ARR_SIZE = 250; // OSC array message size
  histIn = ""; // performance input string
  histOut = ""; // performance output string
  keySig = "—"; // best-guess key signature
  splitKey = true; // toggle split key
  graphVis = false;
  midiRec = false; // toggle midi/osc
  vis = 1; // which graph visualization to display
}

void draw() {
  background(150); // resetting so text (if displayed) is cleared
  keyboard.display();

  // lower-left info box
  fill(255);
  textFont(f, (width+height)/85);
  rect(height/24, 19*height/24, 9*height/24, 4*height/24 + 5); // box
  fill(0);
  if (!post) { 
    text("Notes stored: "+notesStored, 2*height/24, 20*height/24);
  } else {
    text("Total notes: " + (histIn.split("-").length + histOut.split("-").length - 2), 2*height/24, 20*height/24);
  }
  text(" human", 3*height/24, 21*height/24);
  text(" system", 3*height/24, 22*height/24);
  if (!splitKey) {
    text(" both", 3*height/24, 23*height/24);
    fill(255, 41, 41); // red
    rect(2*height/24, 22.5*height/24, .5*height/24, .5*height/24);
  }
  fill(245, 159, 0); // orange
  rect(2*height/24, 20.5*height/24, .5*height/24, .5*height/24);
  fill(41, 77, 255); // fill RGB values
  rect(2*height/24, 21.5*height/24, .5*height/24, .5*height/24);

  fill(0);
  if (graphVis) {
    textFont(f, (width+height)/60);
    text("I think you're playing in " + keySig, width/2, 15*height/20);
  } else {
    textFont(f, (width+height)/50);
    text("I think you're playing in " + keySig, height/16, 2*height/6 - height/75);
  }
  textFont(f, (width+height)/85);

  // post-analysis indicator
  if (post) {
    fill(255, 189, 189);
    rect(height/20, 1.2*height/20, 4*height/20, height/20);
    fill(0);
    text("Post-Analysis", 1.1*height/20, 2.25*height/24);
  }

  // mode indicator message
  fill(0);
  if (midiRec) {
    text("Mode: MIDI", height/20, height/20);
  } else {
    text("Mode: OSC", height/20, height/20);
  }

  //println("in: " + histIn);
  //println("out: " + histOut);

  // midi loop
  if (midiRec) {
    // handle logic for updating notesStored, clocks every second
    if (millis() > prevTime + intervalTime)
    {
      // adding notesStored to queue
      if (secNotes == 0 && queue.getLength() == 0) {
        // hasn't started playing yet, don't add
      } else {
        queue.queueEnqueue(secNotes);
      }
      secNotes = 0; // resetting notes this second

      // update notesStored with sufficient input
      if (queue.getLength() == 30) {
        //println("This is getting triggered");
        notesStored = 10 + Math.round(20*(queue.getAvg())); // updating notes stored
      }

      //queue.queueDisplay();
      prevTime = millis();
    }

    // get amount of notes to take, take maximum if post (overflows handled), notesStored otherwise
    int currentNoteTake = 0;
    if (post) {
      currentNoteTake = Math.max(histIn.split("-").length, histOut.split("-").length);
    } else { 
      currentNoteTake = notesStored;
    }

    // update keyboard heatmap
    keyboard.updateInFreqs(getFrequenciesFromMidiString(histIn, currentNoteTake));
    keyboard.updateOutFreqs(getFrequenciesFromMidiString(histOut, currentNoteTake));
  }
}

/**
 * Clicking the mouse toggles empirical probability labels beneath keys.
 */
void mouseClicked() {
  keyboard.toggleNumbers();
}

/**
 * Controls for visualization
 */
void keyPressed() {
  switch (key) {
  case 'p': // toggle post analysis
    post = !post;
    break;
  case 's': // split the keys
    splitKey = !splitKey;
    break;
  case 'm': // toggle midi/osc
    midiRec = !midiRec;
    clearProgram();
    break;
  case 'c': // clear session
    clearProgram();
    break;
  case 'g': // toggle visualization mode
    graphVis = !graphVis;
    break;
  case 'v': // change graph
    vis++;
    break;
  }
}

/**
 * Function to clear all of program's memory
 */
void clearProgram() {
  queue.clear();
  histIn = "";
  histOut = "";
  notesStored = 40;
  lastNotes = 0;
  keySig = "—";
  vis = 1;
  keyboard.updateInFreqs(getFrequenciesFromMidiString(histIn, histIn.split("-").length));
  keyboard.updateOutFreqs(getFrequenciesFromMidiString(histOut, histOut.split("-").length));
}

/**
 * Updates amount of notes taken as sample in visualization to display heatmap
 */
void updateNotesStored(String[] noteVals) {
  // adjusting notes stored (only if we have at least 30 seconds of data)
  String[] newNotes = noteVals[ARR_SIZE-1].split("-"); // array of notes in last chunk (gain of message transmitted)

  if (Arrays.equals(noteVals, lastArray)) { // if no input, add 0 to notes queue
    queue.queueEnqueue(0);
    println("no new input");
  } else {
    queue.queueEnqueue(newNotes.length); // adding most recent amt of notes (in this one second)
  }

  //println("New notes: " + newNotes);
  //queue.queueDisplay(); // debugging
  lastArray = noteVals;
  //println(queue.getLength());
  if (queue.getLength() >= 30) { // if we have sufficient input
    //println("This is getting triggered");
    notesStored = 10 + Math.round(20*(queue.getAvg())); // updating notes stored
  }
}

/**
 * to update key signature (right now just takes most frequent note)
 */
void updateKeySig(int[] notesFreq) {
  int[] octaveFreq = new int[12];
  for (int i=0; i<12; i++) {
    // for each note
    octaveFreq[i] = 0;
    for (int j=0; j<7; j++) {
      // for each octave
      int noteInd = (3 + i) + j*12; // (offset to C1 + note) + octave offset
      octaveFreq[i] += notesFreq[noteInd]; // increment by note, octave
    }
  }
  // manually incrementing keys not in the loop
  octaveFreq[9] += notesFreq[0]; // A0
  octaveFreq[10] += notesFreq[1]; // Bb0
  octaveFreq[11] += notesFreq[2]; // B0
  octaveFreq[0] += notesFreq[87]; // C8

  // getting most frequent note
  int maxNote = 0;
  for (int i=1; i<12; i++) {
    if (octaveFreq[i] > octaveFreq[maxNote]) { 
      maxNote = i;
    }
  }

  keySig = noteToText[maxNote]; // updating text
  
  // checking frequency of third to guess major/minor
  if (octaveFreq[(maxNote+3)%12] > octaveFreq[(maxNote+4)%12]) {
    // if third is normally flat
    keySig += " Minor";
  } else {
    keySig += " Major";
  }
}

/**
 * Function to get the array of frequencies of midi notes from a string formatted correctly
 */
int[] getFrequenciesFromMidiString(String midi, int notesTake) {
  int[] notesFreq = new int[88];
  for (int i=0; i<88; i++) {
    notesFreq[i] = 0;
  }

  if (midi == "" || notesTake == 0) {
    // if no notes, no frequencies
    return notesFreq;
  }

  String[] noteArray = midi.replaceAll("(0,)*", "").replaceAll(",", "").split("-"); // get array of just notes
  String[] noteVals = Arrays.copyOfRange(noteArray, Math.max(0, noteArray.length-notesTake), noteArray.length); // take last <notesStored> notes

  // increment in frequency array, adjusting for MIDI values
  for (String note : noteVals) {
    notesFreq[Integer.parseInt(note)-21]++;
  }

  // with array of notes of length notesStored, try to figure out key signature
  updateKeySig(notesFreq); // also called during output

  return notesFreq;
}

/**
 * Recieve midi input if note is played (either by input/output)
 */
void noteOn(int channel, int pitch, int velocity, long timestamp, String bus_name) {
  if (!midiRec) { 
    return;
  }

  if (bus_name == "input") {
    histIn += String.valueOf(pitch) + "-";
    secNotes++;
  } else if (bus_name == "output") {
    histOut += String.valueOf(pitch) + "-";
  } else { 
    println("Unknown bus encountered when recieving note.");
  }
}

/**
 * Receives input from user input OSC message '/InputMemory'
 */
void inputReceive(String inMemory) {
  if (midiRec) { 
    return;
  }
  // this is clocked every second from the system
  //println("OSC Message triggered");

  String[] noteVals = inMemory.split(","); // splitting on chunks
  //println(inMemory); // debugging
  //println("len: " + noteVals.length);
  //println("input " + Arrays.toString(noteVals));

  if (noteVals[ARR_SIZE-1].length() == 1 && (int) noteVals[ARR_SIZE-1].charAt(0) == 48) { // if no input memory do not try to access array
    println("no input memory");
    return;
  }

  if (!Arrays.equals(noteVals, lastArray)) {
    histIn += noteVals[ARR_SIZE-1]; // append current notes to history (only do this if update)
  }

  updateNotesStored(noteVals);


  if (post) {
    keyboard.updateInFreqs(getFrequenciesFromMidiString(histIn, histIn.split("-").length));
  } else {
    keyboard.updateInFreqs(getFrequenciesFromMidiString(inMemory, notesStored));
  }
}

/**
 * Receives and handles input from system input OSC message '/OutputMemory'
 * <p>
 * Output string must be in the format: string of leading 0s + integer midi values separated by '-'
 */
void outputReceive(String outMemory) {
  if (midiRec) { 
    return;
  }

  String[] noteVals = outMemory.replaceAll("(0,)*", "").replaceAll(",", "").split("-"); // array of just notes
  //println("output " + Arrays.toString(noteVals)); // outputs notes

  if (outMemory.replaceAll("(0,)*", "").replaceAll(",", "").length() == 1) { // no output memory (length 1)
    println("no output memory");
    return;
  }

  if (!Arrays.equals(noteVals, lastOutArray)) {
    histOut += outMemory.split(",")[ARR_SIZE-1]; // append current notes to outgoing history (only do this if update)
  }

  lastOutArray = noteVals;

  if (post) {
    keyboard.updateOutFreqs(getFrequenciesFromMidiString(histOut, histOut.split("-").length));
  } else {
    keyboard.updateOutFreqs(getFrequenciesFromMidiString(outMemory, notesStored));
  }
}


// taken from camick.com, entirely for converting HSL to RGB for heat map
float[] toRGB(float h, float s, float l, float alpha)
{
  if (s <0.0f || s > 100.0f)
  {
    String message = "Color parameter outside of expected range - Saturation";
    throw new IllegalArgumentException( message );
  }

  if (l <0.0f || l > 100.0f)
  {
    String message = "Color parameter outside of expected range - Luminance";
    throw new IllegalArgumentException( message );
  }

  if (alpha <0.0f || alpha > 1.0f)
  {
    String message = "Color parameter outside of expected range - Alpha";
    throw new IllegalArgumentException( message );
  }

  //  Formula needs all values between 0 - 1.

  h = h % 360.0f;
  h /= 360f;
  s /= 100f;
  l /= 100f;

  float q = 0;

  if (l < 0.5)
    q = l * (1 + s);
  else
    q = (l + s) - (s * l);

  float p = 2 * l - q;

  float r = Math.max(0, HueToRGB(p, q, h + (1.0f / 3.0f)));
  float g = Math.max(0, HueToRGB(p, q, h));
  float b = Math.max(0, HueToRGB(p, q, h - (1.0f / 3.0f)));

  r = Math.min(r, 1.0f);
  g = Math.min(g, 1.0f);
  b = Math.min(b, 1.0f);

  //return new Color(r, g, b, alpha);
  float[] res = {r*255, g*255, b*255};
  return res;
}

float HueToRGB(float p, float q, float h)
{
  if (h < 0) h += 1;

  if (h > 1 ) h -= 1;

  if (6 * h < 1)
  {
    return p + ((q - p) * 6 * h);
  }

  if (2 * h < 1 )
  {
    return  q;
  }

  if (3 * h < 2)
  {
    return p + ( (q - p) * 6 * ((2.0f / 3.0f) - h) );
  }

  return p;
}

/**
 * Returns scaled version of probability based on exponential rise function
 */
float getLume(double prob) {
  return ((2/(1+ (float) Math.exp(-12*prob))) - 1.0);
  //return ((1/(1+ (float) Math.exp(-12*(prob-.3)))));
}
