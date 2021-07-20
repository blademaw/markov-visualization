# Markov Visualization

A project about visualizing the inner workings and output of the AI-based music accompanist & improviser [goldash-system](https://github.com/yeeking/goldash-system).

## Using the Visualization

### Dependencies

* Requires the following Processing libraries: 
	* [oscP5](http://www.sojamo.de/libraries/oscP5/) — for receiving OSC messages
	* [grafica](https://jagracar.com/grafica.php) — for graphs & plotting
	* [MidiBus](http://www.smallbutdigital.com/projects/themidibus/) — for detecting MIDI input

### Executing program

* Ensure OSC message listening port is same as system's outgoing port
* Ensure MIDI busses are correctly selected for user input & system output
* Run `visualization_main.pde` alongside system (before starting to play)
* Visualization can be tweaked real-time with the following controls:
	* `c` — resets & clears visualization's memory
	* `s` — toggles split keys in favor of overlap color
	* `p` — toggles post analysis for viewing entire performance statistics
	* `m` — changes mode of operation (see below)
	* mouse click — toggles empirical probabilities of keys (normalized frequency)
### Modes of Operation

#### 1. Open Sound Control (OSC)

Not preferred. Receive key presses & system output via OSC messages clocked by the system every second. This means there is a (<1s) lag between pressing keys and the consequent visualization. The default port for OSC messages sent by the system is 9001 (on localhost).

#### 2. MIDI

Preferred. Receive key presses & system output via MIDI input from user and system. No lag & instantaneous visualization.

### Additional information

* Built entirely under Processing 3.5.4

## Acknowledgements

* HSL to RGB Java conversion done by [camick.com](http://www.camick.com/java/source/HSLColor.java)