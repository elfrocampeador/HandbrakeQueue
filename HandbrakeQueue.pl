#! /usr/bin/perl
## Handbrake CLI Queue Manager Thingy
# Started in the wee hours of 5 November 2016
# Corey "ElFroCampeador" Mendell
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use POSIX qw(strftime);
use Getopt::Long;
use YAML::Tiny; # Going to need this to load our many various config files




# GLOBAL SECTION
# Global Variables
my $script_name = "HandbrakeQueue.pl";
my $global_configuration; # WARNING: This is a hashref.  It needs to be dereferenced as $global_configuration->[0]->{key}->{subkey} etc
my $interactive_mode; # When set to true, log output will be dumped to screen rather than a log file


# Function Calls
Initialize();

# HERE LIVE SUBROUTINES
sub Initialize
{
	my $main_config_file;
	my $session_log_file;
	my $session_log_handle;
	
	GetOptions("config=s" => \$main_config_file,
			   'interactive' => \$interactive_mode)
		or die("ERROR: Couldn't process input parameters.\nUSAGE: perl $script_name --config <path_to_main_config_file.yml> [--interactive]\n");
		
	die("ERROR: Main config file must be specified.\nUSAGE: perl $script_name --config <path_to_main_config_file.yml> [--interactive]\n") 
		unless defined($main_config_file);
	
	# Load main configuration
	$global_configuration = YAML::Tiny->read($main_config_file)
		or die("ERROR: Couldn't load main configuration file\n");
	
	if(!$interactive_mode)
	{
		$session_log_file = $global_configuration->[0]->{session_log_path} . strftime("%d%b%Y-%I%M%S%p.txt", localtime);
		open($session_log_handle, '>', $session_log_file)
			or die("ERROR: Couldn't open session log $session_log_file\n");
	
		PrintMessage("New session log created at $session_log_file. There will be no further console output (unless there's an error that can't be logged)");
	}
	
	ProcessInputDirectories($session_log_handle);
	
	PrintMessage("Processing complete.\n", 1) if($interactive_mode);
	PrintMessageToFile($session_log_handle, "Processing complete.\n", 1) unless($interactive_mode);
}

sub ProcessInputDirectories
{
	if(scalar @_ != 1)
	{
		die "ERROR: You passed the wrong parameter set in to PrintMessage\n";
	}
	
	my $session_log_handle = $_[0];

	PrintMessage("Spinning through input_paths...", 1) if($interactive_mode);
	PrintMessageToFile($session_log_handle, "Spinning through input_paths...", 1) unless($interactive_mode);
	
	foreach my $path (@{$global_configuration->[0]->{input_paths}})
	{
		if(-e $path && -d $path) # If the path exists, and is in fact a directory
		{
			######## DO THINGS IN HERE
			########	Specifically, load up local config
			########    Then spin through files in the path
		}
		else
		{
			PrintMessage("WARNING: input directory $path does not exist.  It will be skipped.", 1) if($interactive_mode);
			PrintMessageToFile($session_log_handle, "WARNING: input directory $path does not exist.  It will be skipped.", 1) unless($interactive_mode);
		}
	}
	
	PrintMessage("Finished spinning through input_paths", 1) if($interactive_mode);
	PrintMessageToFile($session_log_handle, "Finished spinning through input_paths", 1) unless($interactive_mode);
}


# Prints a message to stdout.  Takes two parameters... the message to print, and 1 or 0 indicating whether or not to include a timestamp
sub PrintMessage
{
	my $message;
	my $include_timestamp;
	my $timestamp = strftime("%d %b %Y - %I:%M:%S %p", localtime);
	
	if(scalar @_ > 2 || scalar @_ < 1)
	{
		die "ERROR: You passed the wrong parameter set in to PrintMessage\n";
	}
	elsif(scalar @_ == 1)
	{
		$include_timestamp = 0;
	}
	else
	{
		if($_[1] > 0)
		{
			$include_timestamp = 1;
		}
		else
		{
			$include_timestamp = 0;
		}
	}
		
	$message = $_[0];
	
	if($include_timestamp == 1)
	{
		print "[$timestamp] $message\n";
	}
	else
	{
		print "$message\n";
	}
}

# Prints a message to file.  Takes three parameters... a file handle, the message to print, and 1 or 0 indicating whether or not to include a timestamp
sub PrintMessageToFile
{
	my $file_handle;
	my $message;
	my $include_timestamp;
	my $timestamp = strftime("%d %b %Y - %I:%M:%S %p", localtime);
	
	if(scalar @_ > 3 || scalar @_ < 2)
	{
		die "ERROR: You passed the wrong parameter set in to PrintMessage\n";
	}
	elsif(scalar @_ == 2)
	{
		$include_timestamp = 0;
	}
	else
	{
		if($_[2] > 0)
		{
			$include_timestamp = 1;
		}
		else
		{
			$include_timestamp = 0;
		}
	}
		
	$file_handle = $_[0];
	$message = $_[1];
	
	if($include_timestamp == 1)
	{
		print $file_handle "[$timestamp] $message\n";
	}
	else
	{
		print $file_handle "$message\n";
	}
}
