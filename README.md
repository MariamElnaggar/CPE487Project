# Instructions
- From https://github.com/byett/dsd/blob/CPE487-Spring2025/projects/README.md
## Submission (80% of your project grade):
* Your final submission should be a github repository of very similar format to the labs themselves with an opening README document with the expected components as follows:
	* A description of the expected behavior of the project, attachments needed (speaker module, VGA connector, etc.), related images/diagrams, etc. (10 points of the Submission category)
		* The more detailed the better – you all know how much I love a good finite state machine and Boolean logic, so those could be some good ideas if appropriate for your system. If not, some kind of high level block diagram showing how different parts of your program connect together and/or showing how what you have created might fit into a more complete system could be appropriate instead.
	* A summary of the steps to get the project to work in Vivado and on the Nexys board (5 points of the Submission category)
 	* Description of inputs from and outputs to the Nexys board from the Vivado project (10 points of the Submission category)
  		* As part of this category, if using starter code of some kind (discussed below), you should add at least one input and at least one output appropriate to your project to demonstrate your understanding of modifying the ports of your various architectures and components in VHDL as well as the separate .xdc constraints file.
	* Images and/or videos of the project in action interspersed throughout to provide context (10 points of the Submission category)
	* “Modifications” (15 points of the Submission category)
		* If building on an existing lab or expansive starter code of some kind, describe your “modifications” – the changes made to that starter code to improve the code, create entirely new functionalities, etc. Unless you were starting from one of the labs, please share any starter code used as well, including crediting the creator(s) of any code used. It is perfectly ok to start with a lab or other code you find as a baseline, but you will be judged on your contributions on top of that pre-existing code!
		* If you truly created your code/project from scratch, summarize that process here in place of the above.
	* Conclude with a summary of the process itself – who was responsible for what components (preferably also shown by each person contributing to the github repository!), the timeline of work completed, any difficulties encountered and how they were solved, etc. (10 points of the Submission category)
* And of course, the code itself separated into appropriate .vhd and .xdc files. (50 points of the Submission category; based on the code working, code complexity, quantity/quality of modifications, etc.)
* You are not really expected to be github experts – as long as one of you can confidently create the repository and help others add to it, that should be sufficient. If no group members fall under this criteria, discuss with me as soon as possible.
	* This is a group assignment, and for the most part you are graded as a group. I reserve the right to modify single student grades for extenuating circumstances, such as a clear lack of participation from a group member. You are allowed to rely on the expertise of your group members in certain aspects of the project, but you should all have at least a cursory understanding of all aspects of your project.

## Presentation (20% of your project grade):
* Additionally, you’ll be expected to give a demonstration + presentation during the final exam period. This can take the form of a live demonstration + informal discussion (the encouraged option in most situations that will be given more leeway from any technical difficulties), or a pre-created video including the project in action + slides describing much of the same content as the github submission (a backup option primarily for groups that will be missing multiple members during the final exam period).
	* Though this a group assignment, the presentation in particular is an area where I will penalize students who do not participate in the presentation/discussion or who are unable to answer questions about their project.

## Extra Notes:

* If you need a single copy of any of the hardware (attachments) we use during the course, that should not be an issue. If you need multiple copies, there may be some “wait and see” situations and/or you may have minimal time to test the full implementation with all components.
* For more complex projects that would require hardware that you do not already readily have access to, it is sufficient to model the desired final system in some way. For example, showing the output of a controller for a microwave or other digital system on the LCD screen instead of actually controlling a microwave.
	* That said, if you already own these needed components, by all means use them!
* If you are still “attached” to a particular lab (calculator, pong, etc.), you may still explore these areas further with additional functionality (many more operations for a calculator, multiple players or other modifications for pong, etc.)
* You may also start with some of the components from the simulation exercices and approach the project from more of a true digital logic perspective using combinational and sequential logic techniques in a sufficiently advanced way.
* You may instead peruse the following list of projects (or outside project sources) for some ideas. Some of these were personally vetted by me (Prof. Yett), others came prior to my time at Stevens. 
* If you choose to start from an existing project and make substanstial changes/improvements, you must cite your starting place! This goes for the labs, these projects, or any others you may find. Do not pass off someone else's work as your own and you'll do just fine.
# Our Project
A reaction game to measure the user's reaction time.
Base code repositories for our project:
- For the clock: https://github.com/cfoote5/CPE487_FinalProject
- For the Display: https://github.com/beartwoz/Whack-A-Mole
## Summary
For our project we decided to work on creating a reaction test that would challege the player to react to the display as fast as they can. From when the game begins a stopwatch would start on the display of the Nexys A7 100T board and stop once the user hit the button corresponding to what is shown on the VGA screen. In order to accomplish this we used base code from the clock and whack-a-mole projects which can be found [here](-------). These projects provided a good starting point for implementing a clock that would display milliseconds and developing the VGA display that the player would interact with.
## Expected Behavior
![Demonstration](-------)
- The clock will start from zero and count until the player successfully hits the necessary button.
- The VGA screen will display a four blocks (positioned up, down, left, and right) and whichever block turns green the player must hit the corresponding button on the board.
- The goal is to test how fast the player can react.
- The game will play for three rounds.
- The average time over the three rounds is the players score.
## Requirments
- Nexys A7 100T Board
- Micro-USB to USB Cable
- Computer with Vivado installed
- Monitor
- VGA Cable
