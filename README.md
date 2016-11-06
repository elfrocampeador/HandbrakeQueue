# HandbrakeQueue
A simple (one hopes) queueing system to automate encoding of files with Handbrake's CLI

## Overview
This package was designed because I got kind of tired of manually configuring Handbrake's GUI on my PC whenever I needed to encode
something, and then basically not being able to do anything with my PC while its CPU was pegged with encoding work. Some inspiration
drawn from https://github.com/gorillaninja/process-queue, though I haven't actually looked at any of the code.

## Features
Each time it is invoked, HandBrakeQueue.pl will search through a configurable list of input directories for appropriate files
to encode based on file extension.  It then invokes the handbrake CLI with settings specified in a profile YAML file.  The global
configuration can be overridden to an extent at the input directory level, and each input file may have its own configuration override
as well.  Directory config files should be named local_configuration.yml and file overrides should be videosfilename.yml

Currently, local_configuration files support the following keys:  output_path, profile
Individual file override files support the following keys: output_path, output_filename, profile, title
(where profile is the full path to the profile yaml file)

HandbrakeQueue.pl produces two levels of output logging.  Output from the handbrake cli gets logged individually for each input file
to a path specified in the global configuration file.  All other output is logged either to the screen if the --interactive flag is 
set, or otherwise to a session log file which is written to a path specified in the global configuration file.

## Things you need
In order to run this script, you need:
   1. Linux
   2. Perl including the following modules
     * Getopt::Long
     * YAML::Tiny
	 * File::Which
     * Capture::Tiny
   3. HandbrakeCLI
