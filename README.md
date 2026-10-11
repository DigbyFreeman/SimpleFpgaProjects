# SimpleFpgaProjects
4 simple fpga projects. I did these on a Cyclone V, in VHDL.

Altera/Intel Cyclone V SoC FPGA Development Board, built around the 5CSXFC6D6F31C6 

1. Blinky:

2. Button counter:
Issue with button bounce back
Solved using debounce

3. Reaction Timer:
Hold down 0, until all LEDs turn on, then release. Press 1 to reset. 
Couldn't find an easy method to introduce a numerical output - in theory,
UART or the LCD screen provided on the device. In reality 
I have to download a seperate program called QSys, and plug in another 
peripheral. I also couldn't find the correct, older version of this 
seperate program. I will probably come back to this at some point.

4. Dice
This was a mixture of the two previous programs, reaction timer and button counter. 
Hold down 0, continually spin dice, until you let go, then stop on the final number. 
Uses LEDs to give output 1-6 - in binary.
