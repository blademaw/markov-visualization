# Markov Visualization

A project about visualizing the inner workings and output of the AI-based music accompanist & improviser [goldash-system](https://github.com/yeeking/goldash-system).

## Using the Visualization

### Dependencies

* Requires the following Processing libraries: 
	* [oscP5](http://www.sojamo.de/libraries/oscP5/) — for receiving OSC messages
	* [grafica](https://jagracar.com/grafica.php) — for graphs & plotting

### Executing program

* Ensure OSC message listening port is same as system's outgoing port
* Run `visualization_main.pde` alongside system (ideally before starting to play)
* Visualization aesthetics can be changed in real-time with the following controls:
	* `c` — resets & clears visualization's memory
	* `s` — toggles split keys in favor of overlap color
	* `p` — toggles post analysis for viewing entire performance statistics
	* mouse click — toggles empirical probabilities of keys (normalized frequency)
### Additional information

* Built entirely under Processing 3.5.4

## Acknowledgements

* HSL to RGB Java conversion done by [camick.com](http://www.camick.com/java/source/HSLColor.java)