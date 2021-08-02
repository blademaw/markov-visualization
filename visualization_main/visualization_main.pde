/**
 Created by:
 Jack
 On date:
 14-Jul-2021
 Last updated on:
 02-Aug-2021
 Purpose:
 experiment further with Markov system visualisations
 */

import java.util.*;
import java.awt.Color;
import oscP5.*;
import netP5.*;
import grafica.*;
import themidibus.*;
import controlP5.*;

Keyboard keyboard;
OscP5 oscRec; 
ControlP5 cp5;
RadioButton recModeButton, visButton;
CheckBox midiModeBox, optionsBox;
PFont f;
int notesStored, lastNotes, ARR_SIZE, intervalTime, prevTime, secNotes, vis, bgCol;
float inAvg, outAvg; // average notes/sec human, and system
boolean post, splitKey, midiRec, graphVis, debugMode, opDisplay, disKeySig, disMovAvg;
String histIn, histOut, keySig;
String[] lastArray, lastOutArray;
String[] noteToText = {"C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G", "G#/Ab", "A", "A#/Bb", "B"};
Queue queue = new Queue(30); // averaging notes per second over every 30 last received chunks/seconds
MidiBus outBus; // two MidiBusses for receiving input from user and output from system
GPlot plot, plot1; // two plots (hist, line)
GPointsArray points, pointsOut;

void setup() {
  //fullScreen();
  size(1120, 630);
  //size(2560, 1440); // this should be Processing's judgement of a 5120x2880 screen due to 2x pixel density
  //pixelDensity(displayDensity()); // uncomment this for sharper graphics but (possibly) slower performance
  strokeWeight(1);
  f = createFont("Arial", 16, true);

  debugMode = false; // change this to run program in debug mode

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

  if (debugMode) {
    displayAvailableMidiDevices();
  }

  // setting up MidiBus & midi values
  outBus = new MidiBus(this, 1, 0, "output"); // device 2 should be IAC Bus 2, system/user are diff. channels
  intervalTime = 1000; // recieve notes per second (1000ms)
  prevTime = 0;
  secNotes = 0; // number of notes recieved in past second

  // setting up graph visualisations
  int nPoints = 61; // 61 keys
  points = new GPointsArray(nPoints);
  pointsOut = new GPointsArray(nPoints);
  plot = new GPlot(this);

  float graphX = -width*0.078; // if the line chart is not aligned properly, this is the culprit
  float graphYMax = height/20;
  float graphWidth = width*1.108; // if the line is too big for the keyboard, change this
  float graphHeight = 8*height/20;
  initPlots(graphX, graphYMax, graphWidth, graphHeight);

  // setting initial global variables
  post = false; // toggle post analysis
  lastNotes = 0; // notes recieved last OSC tick
  notesStored = 40; // notes to create ongoing/real-time visualisation
  ARR_SIZE = 250; // OSC array message size
  histIn = ""; // performance input string
  histOut = ""; // performance output string
  keySig = "—"; // best-guess key signature
  splitKey = true; // toggle split key
  graphVis = false;
  midiRec = false; // toggle midi/osc
  vis = 1; // which graph visualisation to display
  bgCol = 150; // initial (grey) background color
  opDisplay = false; // don't display options box by default
  disKeySig = false; // don't display key signature by default
  disMovAvg = false; // don't display moving averages by default

  // control P5 GUI
  cp5 = new ControlP5(this);
  drawGuiOptions();
}

/**
 * Function to display MIDI devices for debugging
 */
void displayAvailableMidiDevices() {
  println("Available MIDI Devices:"); 

  System.out.println("----------Input (from availableInputs())----------");
  String[] available_inputs = MidiBus.availableInputs(); //Returns an array of available input devices
  for (int i = 0; i < available_inputs.length; i++) System.out.println("["+i+"] \""+available_inputs[i]+"\"");

  System.out.println("----------Output (from availableOutputs())----------");
  String[] available_outputs = MidiBus.availableOutputs(); //Returns an array of available output devices
  for (int i = 0; i < available_outputs.length; i++) System.out.println("["+i+"] \""+available_outputs[i]+"\"");

  System.out.println("----------Unavailable (from unavailableDevices())----------");
  String[] unavailable = MidiBus.unavailableDevices(); //Returns an array of unavailable devices
  for (int i = 0; i < unavailable.length; i++) System.out.println("["+i+"] \""+unavailable[i]+"\"");
}

/**
 * Function to initialize Grafica plots
 */
void initPlots(float graphX, float graphYMax, float graphWidth, float graphHeight) {
  plot.setPos(graphX, graphYMax); // top-left corner
  plot.setYLim(0, 1); // max 1 normalized frequency
  plot.setDim(graphWidth, graphHeight);
  plot.setLineColor(color(178, 206, 252));
  plot.addLayer("layer 1", pointsOut);
  plot.startHistograms(GPlot.VERTICAL);

  // second line for system input
  plot1 = new GPlot(this);
  plot1.setPos(graphX, graphYMax);
  plot1.setYLim(0, 1);
  plot1.setDim(graphWidth, graphHeight);
  plot1.setLineColor(color(255, 206, 162));
  plot1.startHistograms(GPlot.VERTICAL);
}

/**
 * Function to intialize the GUI elements of the option box
 */
void drawGuiOptions() {
  recModeButton = cp5.addRadioButton("radioButton") // Graph/keyboard
    .setPosition(6.25*width/24, 20.5*height/24)
    .setSize((int) (0.5*width)/24, (int) (.75*height)/24)
    .setColorForeground(150)
    .setColorActive(color(160, 0, 0))
    .setColorLabel(155)
    .setItemsPerRow(1)
    .setSpacingColumn(5)
    .addItem("Graph", 0)
    .addItem("Keyboard", 1);

  for (Toggle t : recModeButton.getItems()) {
    t.getCaptionLabel().setColorBackground(255);
    t.getCaptionLabel().getStyle().moveMargin(-7, 0, 0, -3);
    t.getCaptionLabel().getStyle().movePadding(7, 0, 0, 3);
    t.getCaptionLabel().getStyle().backgroundWidth = 45;
    t.getCaptionLabel().getStyle().backgroundHeight = 13;
  }
  recModeButton.activate(1);

  visButton = cp5.addRadioButton("radioButton2") // choosing graph viz.
    .setPosition(8.25*width/24, 20.5*height/24)
    .setSize((int) (0.5*width)/24, (int) (.75*height)/24)
    .setColorForeground(150)
    .setColorActive(color(160, 0, 0))
    .setColorLabel(155)
    .setItemsPerRow(1)
    .setSpacingColumn(5)
    .addItem("Line Filled", 0)
    .addItem("Line Stroke", 1)
    .addItem("Histogram", 2);
  visButton.activate(1);

  for (Toggle t : visButton.getItems()) {
    t.getCaptionLabel().setColorBackground(255);
    t.getCaptionLabel().getStyle().moveMargin(-7, 0, 0, -3);
    t.getCaptionLabel().getStyle().movePadding(7, 0, 0, 3);
    t.getCaptionLabel().getStyle().backgroundWidth = 45;
    t.getCaptionLabel().getStyle().backgroundHeight = 13;
  }

  midiModeBox = cp5.addCheckBox("checkBox") // MIDI/OSC toggle
    .setPosition(6.25*width/24, 22.25*height/24)
    .setSize((int) (0.5*width)/24, (int) (.75*height)/24)
    .setItemsPerRow(1)
    .setSpacingColumn(30)
    .setSpacingRow(20)
    .addItem("MIDI", 1)
    ;

  optionsBox = cp5.addCheckBox("checkBox2") // other options
    .setPosition(11.25*width/24, 20.5*height/24)
    .setSize((int) (0.5*width)/24, (int) (.75*height)/24)
    .setItemsPerRow(3)
    .setSpacingColumn(2*width/24)
    .setSpacingRow((int) (.75*height)/24)
    .addItem("Split keys", 1)
    .addItem("Post-analysis", 1)
    .addItem("Key signature", 1)
    .addItem("Frequency labels", 1)
    .addItem("Moving averages", 1)
    ;
  optionsBox.activate(0);
  optionsBox.activate(2);
  optionsBox.activate(4);
}

void draw() {
  background(bgCol); // resetting so text (if displayed) is cleared
  keyboard.display(); // displaying keyboard
  drawLegend(); // drawing legend

  // hiding GUI if no options box
  if (opDisplay) {
    drawOptionBox();
    recModeButton.show();
    visButton.show();
    midiModeBox.show();
    optionsBox.show();
  } else {
    recModeButton.hide();
    visButton.hide();
    midiModeBox.hide();
    optionsBox.hide();
  }

  if (disKeySig) {
    drawKeySignature();
  }
  textFont(f, (width+height)/85);

  // post-analysis indicator
  if (post) {
    fill(255, 189, 189);
    rect(height/20, 1.2*height/20, 4*height/20, height/20);
    fill(0);
    text("Post-Analysis", 1.1*height/20, 2.25*height/24);
    fill(255);
  }

  // mode indicator message
  fill(0);
  if (midiRec) {
    text("Mode: MIDI", height/20, height/20);
  } else {
    text("Mode: OSC", height/20, height/20);
  }

  if (debugMode) {
    println("in: " + histIn);
    println("out: " + histOut);
  }

  // midi loop - only triggers if 
  if (midiRec) {
    midiNotesStored();
  }
}

/**
 * Updates notes stored with MIDI input
 */
void midiNotesStored() {
  // handle logic for updating notesStored, clocks every second
  if (millis() > prevTime + intervalTime)
  {
    // adding new notes per second to queue
    if (secNotes == 0 && queue.getLength() == 0) {
      // hasn't started playing yet, don't add
    } else {
      queue.queueEnqueue(secNotes);
    }
    secNotes = 0; // resetting notes this second for next second

    // updating notesStored if there is sufficient input
    if (queue.getLength() == 30) {
      notesStored = 10 + Math.round(20*(queue.getAvg())); // updating notes stored
    }

    prevTime = millis();
  }

  // get amount of notes to take, take maximum if post-analysis active (overflows handled)
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

/**
 * Draws key signature text
 * :precondition: disKeySig is true
 */
void drawKeySignature() {
  fill(0);
  if (graphVis) {
    textFont(f, (width+height)/60);
    text("I think you're playing in " + keySig, width/2, 15*height/20);
  } else if (!graphVis) {
    textFont(f, (width+height)/50);
    text("I think you're playing in " + keySig, height/16, 2*height/6 - height/75);
  }
}

/**
 * Draws legend
 */
void drawLegend() {
  fill(255);
  textFont(f, (width+height)/85);
  rect(width/24, 19*height/24, 5*width/24, 4.5*height/24); // box
  fill(0);
  if (!post) { 
    text("Notes stored: "+notesStored, 1.5*width/24, 20*height/24);
  } else {
    text("Total notes: " + (histIn.split("-").length + histOut.split("-").length - 2), 1.5*width/24, 20*height/24);
  }
  text(" human", 2.5*width/24, 21*height/24);
  text(" system", 2.5*width/24, 22*height/24);
  if (!splitKey) {
    text(" both", 2.5*width/24, 23*height/24);
    fill(255, 41, 41); // red
    rect(1.5*width/24, 22.5*height/24, .5*width/24, .5*height/24);
  }
  fill(245, 159, 0); // orange
  rect(1.5*width/24, 20.5*height/24, .5*width/24, .5*height/24);
  fill(41, 77, 255); // fill RGB values
  rect(1.5*width/24, 21.5*height/24, .5*width/24, .5*height/24);
}

/**
 * Draws options box (if toggled)
 */
void drawOptionBox() {
  fill(bgCol-10);
  rect(6*width/24, 19*height/24, 17*width/24, 4*height/24 + 5); // box

  fill(0);
  text("Modes", 6.25*width/24, 20.05*height/24);
  text("Visualisation", 8.25*width/24, 20.05*height/24);
  text("Options", 11.25*width/24, 20.05*height/24);
}

/**
 * Receive events from ControlP5 elements
 */
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(recModeButton)) {
    if (theEvent.getValue() == 0) { // toggle graph/keyboard
      graphVis = true;
    } else { 
      graphVis = false;
    }
  } else if (theEvent.isFrom(visButton)) {
    vis = (int) theEvent.getValue(); // select graph vis based on radio button
  } else if (theEvent.isFrom(midiModeBox)) { // toggle midi/osc
    if (midiModeBox.getArrayValue()[0] == 1) {
      midiRec = true;
      clearProgram();
    } else {
      midiRec = false;
      clearProgram();
    }
  } else if (theEvent.isFrom(optionsBox)) { // extra options
    float[] optionsList = optionsBox.getArrayValue();
    if (optionsList[0] == 1) {
      splitKey = true;
    } else {
      splitKey = false;
    }

    if (optionsList[1] == 1) { // post-analysis
      post = true;
    } else {
      post = false;
    }

    if (optionsList[2] == 1) { // key signature
      disKeySig = true;
    } else {
      disKeySig = false;
    }

    if (optionsList[3] == 1) { // frequency labels
      keyboard.toggleNumbers(true);
    } else {
      keyboard.toggleNumbers(false);
    }

    if (optionsList[4] == 1) { // moving average
      disMovAvg = true;
    } else {
      disMovAvg = false;
    }
  }
}

/**
 * Hidden controls for visualisation
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
  case 'g': // toggle visualisation mode
    graphVis = !graphVis;
    break;
  case 'v': // change graph
    vis++;
    break;
  case 'i':
    bgCol += 5;
    break;
  case 'd':
    bgCol -= 5;
    break;
  case ' ':
    opDisplay = !opDisplay;
    break;
  }
}

/**
 * Function to clear memory of visualisation
 */
void clearProgram() {
  queue.clear();
  histIn = "";
  histOut = "";
  notesStored = 40;
  lastNotes = 0;
  keySig = "—";
  vis = 1;
  keyboard.updateInFreqs(getFrequenciesFromMidiString(histIn, 0));
  keyboard.updateOutFreqs(getFrequenciesFromMidiString(histOut, 0));
}

/**
 * Updates amount of notes taken as sample in visualisation to display heatmap
 * Only used for OSC mode
 */
void updateNotesStored(String[] noteVals) {
  // adjusting notes stored (only if we have at least 30 seconds of data)
  String[] newNotes = noteVals[ARR_SIZE-1].split("-"); // array of notes in last chunk (gain of message transmitted)

  if (Arrays.equals(noteVals, lastArray)) { // if no input, add 0 to notes queue
    queue.queueEnqueue(0);
    if (debugMode) { 
      println("no new input");
    }
  } else {
    queue.queueEnqueue(newNotes.length); // adding most recent amt of notes (in this one second)
  }

  if (debugMode) {
    println("New notes: " + newNotes + ". Queue:");
    queue.queueDisplay();
  }

  lastArray = noteVals; // save the last array for future comparison
  if (queue.getLength() >= 30) { // if we have sufficient input
    notesStored = 10 + Math.round(20*(queue.getAvg())); // updating notes stored
  }
}

/**
 * To update key signature
 * Takes most frequent note and more popular minor/major third
 */
void updateKeySig(int[] notesFreq) {
  int[] octaveFreq = new int[12];
  for (int i=0; i<12; i++) {
    // for each note
    octaveFreq[i] = 0;
    for (int j=0; j<7; j++) {
      // for each octave
      int noteInd = (3 + i) + j*12; // (offset to C1 + this note) + octave
      octaveFreq[i] += notesFreq[noteInd]; // increment by freq[note on octave]
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
 * Used for OSC & MIDI
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

  // processing OSC message
  String[] noteArray = midi.replaceAll("(0,)*", "").replaceAll(",", "").split("-"); // get array of just notes
  String[] noteVals = Arrays.copyOfRange(noteArray, Math.max(0, noteArray.length-notesTake), noteArray.length); // take last <notesStored> notes

  // increment in frequency array, adjusting for MIDI values
  for (String note : noteVals) {
    if (Integer.parseInt(note) > 96 || Integer.parseInt(note) < 36) {
      if (debugMode) {
        println("Encountered note out of current bounds.");
      }
    } else {
      notesFreq[Integer.parseInt(note)-21]++;
    }
  }

  updateKeySig(notesFreq); // update key signature

  return notesFreq;
}

/**
 * Recieve midi input if note is played (either by input/output)
 */
void noteOn(int channel, int pitch, int velocity, long timestamp, String bus_name) {
  if (!midiRec) { 
    return;
  }

  if (channel == 1) {
    // this is human input
    histIn += String.valueOf(pitch) + "-";
    secNotes++;
  } else if (channel == 0) {
    // system output
    histOut += String.valueOf(pitch) + "-";
  } else { 
    println("Unknown channel encountered when recieving note.");
  }
}

/**
 * Function to act on controller changes by the system
 */
void controllerChange(int channel, int number, int value, long timestamp, String bus_name) {
  // triggers for both OSC Mode and MIDI
  switch (number) {
  case 32: // cycling through visualisations
    vis++;
  case 123: // resetting system & clearing memory
    clearProgram();
  }
}


/**
 * Receives input from user input OSC message '/InputMemory'
 */
void inputReceive(String inMemory) {
  if (midiRec) { 
    return;
  }
  // this is clocked every second from the system with OSC enabled system-side

  String[] noteVals = inMemory.split(","); // splitting on chunks

  if (noteVals[ARR_SIZE-1].length() == 1 && (int) noteVals[ARR_SIZE-1].charAt(0) == 48) { // if no input memory do not try to access array
    if (debugMode) {
      println("no input memory");
    }
    return;
  }

  if (!Arrays.equals(noteVals, lastArray)) { // if we have new input
    histIn += noteVals[ARR_SIZE-1]; // append current notes to history (only do this if update)
  }

  updateNotesStored(noteVals); // update notes stored

  if (post) {
    keyboard.updateInFreqs(getFrequenciesFromMidiString(histIn, histIn.split("-").length));
  } else {
    keyboard.updateInFreqs(getFrequenciesFromMidiString(inMemory, notesStored));
  }
}

/**
 * Receives and handles input from system input OSC message '/OutputMemory'
 * Output string must be in the format: string of leading 0s + integer midi values separated by '-'
 */
void outputReceive(String outMemory) {
  if (midiRec) { 
    return;
  }

  String[] noteVals = outMemory.replaceAll("(0,)*", "").replaceAll(",", "").split("-"); // array of just notes

  if (outMemory.replaceAll("(0,)*", "").replaceAll(",", "").length() == 1) { // no output memory (length 1)
    if (debugMode) {
      println("no output memory");
    }
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
