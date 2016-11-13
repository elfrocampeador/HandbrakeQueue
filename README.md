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

### Profile Features
#### Audio
The audio section of an encoder profile may contain the field "encoder" which defaults to copy if not specified.
The value for encoder may be: av_aac, copy:aac, ac3, copy:ac3, copy:dts, copy:dtshd, mp3, copy:mp3, vorbis, flac16, flac24, copy
Specify which tracks to include in the encode by including each track's number in an array subitem called "tracks".
Those tracks may be named by including those names in an array subitem called "track_names".  All spaces in names must be escaped with a \.
#### Video
The video section of an encoder profile may include the following items:
encoder:  Defaults to x264 (for H.264).  May also be mpeg4, mpeg2, VP8, theora, or x265 provided your local installation has the appropriate codec.
encoder_preset: Depends on which encoder you've selected.  Has no default.  
quality: The quality or RF value which which to encode.  The values and meaning of each depends on the encoder selected.  Defaults to 18.
#### Filters
Currently there is only one misc filter supported:  Decomb which should be specified as true or false
#### Subtitles
You can include subtitle tracks in your encode by listing their number in a list in this section called "tracks"
#### Chapters
Specify whether or not to copy chapter marks in your encode by specifying a top level item "chapters" as either true or false

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
   3. HandbrakeCLI
