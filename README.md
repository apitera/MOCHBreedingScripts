# MOCHBreedingScripts
Just some perl scripts I wrote for compiling breeding data from our mountain chickadee system. These data are not to be used without permission from owner.

This script takes in separate text files for different nest boxes at our field site -- each breeding event is recorded in a separate text file named with the box number, elevation, and type of breeding event 
(see "box_instructions.txt" for specific details"). This allows changes to a breeding events to be made easily in a breeding event's text file and the entire script to be rerun.
This was designed to ensure fewer errors in the generation of "master files" and greater ease in creating different types of files based on the desired data scructure output.

The "breeding_scripts.pl" script will take files from the "BoxFiles/" directory and create two text files:
  1) text file specifying all breeding metrics for that season
  2) text file with all nestling banding information

