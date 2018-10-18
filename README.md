# HyperMaze
These scripts were used to run an automated spatial maze testing environment for
rats for behavioral tasks in a neuroscience lab. In general, there are 2 sides:
Arduino side and computer side. Arduinos run C++ code that controls all the
electronics components of the maze. It handles the logic of what to do when it
receives input from an infrared sensor, how many degrees to turn a motor, or for
how long to open a solenoid valve to dispense reward. However, in general,
they are not great to handle all the logic of the session, i.e. what rat is runnning,
for what experiment, and logging files, etc. That is handled the computer
side. 

I include 2 implementations of the computer "side". The first is a GUI program written in MATLAB,
and is the script 'hypermaze.m' above. I eventually switched to Python because
MATLAB is too clunky to fit in a Raspberry Pi, which was much more convenient for me to use.
The Python implementation is the 'plus_maze_reversals.py' script. Furthermore, the script
'DSR_PSR2.ino' is the C++ code that run in the master Arduino, while the script 
'platform2016.ino' is the code that ran in the slave microcontrollers.  

If you work in a lab and are
trying to set up something similar feel free to get in touch with me. You won't
be able to use the code as is, it's very specific to the setup that I had, but
it can serve as a template for your rig. 
