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
use File::Copy;
use File::Spec::Functions;

use run_handbrake;

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
		die "ERROR: You passed the wrong parameter set to ProcessInputDirectories\n";
	}

	my $session_log_handle = $_[0];

	PrintMessage("Spinning through input_paths...", 1) if($interactive_mode);
	PrintMessageToFile($session_log_handle, "Spinning through input_paths...", 1) unless($interactive_mode);

	foreach my $path (@{$global_configuration->[0]->{input_paths}})
	{
		if(-e $path && -d $path) # If the path exists, and is in fact a directory
		{
			PrintMessage("Processing input path $path...", 1) if($interactive_mode);
			PrintMessageToFile($session_log_handle, "Processing input path $path...", 1) unless($interactive_mode);

			my $locally_configured;
			my $output_path = $global_configuration->[0]->{default_output_path};
			my $profile_file = $global_configuration->[0]->{default_profile};

			if(-e $path . "local_config.yml" && -f $path . "local_config.yml") # If a local configuration file is present
			{
				PrintMessage("Local configuration file found, loading it...", 1) if($interactive_mode);
				PrintMessageToFile($session_log_handle, "Local configuration file found, loading it...", 1) unless($interactive_mode);
			

				# Load the local config
				$locally_configured = 1;

				my $local_configuration;
				unless($local_configuration = YAML::Tiny->read($path . "local_config.yml"))
				{
					$locally_configured = 0;
					PrintMessage("WARNING: Couldn't process local configuration file.  Will use defaults", 0) if($interactive_mode);
					PrintMessageToFile($session_log_handle, "WARNING: Couldn't process local configuration file.  Will use defaults", 0) unless($interactive_mode)
				}

				if($locally_configured)
				{
					if(exists $local_configuration->[0]->{output_path})
					{
						$output_path = $local_configuration->[0]->{output_path};
						PrintMessage("Output path overridden, output for files in this directory will go in $output_path", 0) if($interactive_mode);
						PrintMessageToFile($session_log_handle, "Output path overridden, output for files in this directory will go in $output_path", 0) unless($interactive_mode)
					}

					if(exists $local_configuration->[0]->{profile})
					{
						$profile_file = $local_configuration->[0]->{profile};
						PrintMessage("Encoding profile overridden, will use $profile_file instead for files in this directory.", 0) if($interactive_mode);
						PrintMessageToFile($session_log_handle, "Encoding profile overridden, will use $profile_file instead for files in this directory.", 0) unless($interactive_mode)
					}
				}
			}

			# Deal with the files in the path
			ProcessInputFiles($session_log_handle, $path, $output_path, $profile_file);
		}
		else
		{
			PrintMessage("WARNING: input directory $path does not exist.  It will be skipped.", 0) if($interactive_mode);
			PrintMessageToFile($session_log_handle, "WARNING: input directory $path does not exist.  It will be skipped.", 0) unless($interactive_mode);
		}
	}

	PrintMessage("Finished spinning through input_paths", 1) if($interactive_mode);
	PrintMessageToFile($session_log_handle, "Finished spinning through input_paths", 1) unless($interactive_mode);
}

sub ProcessInputFiles
{
	if(scalar @_ != 4)
	{
		die "ERROR: You passed the wrong parameter set to ProcessInputFiles\n";
	}

	my $session_log_handle = $_[0];
	my $input_directory_path = $_[1];
	my $output_directory_path = $_[2];
	my $profile_file = $_[3];
	my $files_processed = 0;
		
	unless(opendir(INPUT_DIR, $input_directory_path))
	{
		PrintMessage("WARNING: Couldn't open input path $input_directory_path... its contents will be skipped.", 0) if($interactive_mode);
		PrintMessageToFile($session_log_handle, "WARNING: Couldn't open input path $input_directory_path... its contents will be skipped.", 0) unless($interactive_mode);
		return;
	}

	while(my $input_filename = readdir(INPUT_DIR))
	{
		my $orig_input_filename = $input_filename;
		#$input_filename =~ s/ /\\ /g; # Escape out spaces
		#$input_filename =~ s/'/\\'/g; # Escape out single quotes
		#$input_filename =~ s/&/\\&/g; # Escape out ampersands
		$input_filename =~ s/(\W)/\\$1/g; # Escape out all special characters

		my $output_filename = $input_filename;
		my $output_title = undef; # The encoder module will try to set this as the output's title, defaults to use --main-feature
        my $output_chapters = undef;

		my $extension_acceptable = 0;
		foreach my $extension (@{$global_configuration->[0]->{input_file_extensions}})
		{
			my $ext = GetFileExtension($input_filename);
			
			if($ext eq $extension)
			{
				$extension_acceptable = 1;
				last;
			}
		}

		if(!$extension_acceptable)
		{
			next;
		}
		
		PrintMessage("Processing $input_directory_path$input_filename...", 1) if($interactive_mode);
		PrintMessageToFile($session_log_handle, "Processing $input_directory_path$input_filename", 1) unless($interactive_mode);

		my $override_config_file = $input_directory_path . $orig_input_filename;
		$override_config_file =~ s/.mkv$/.yml/;

		if(-e $override_config_file && -f $override_config_file)
		{
			PrintMessage("Configuration override file for $input_directory_path$input_filename found, loading it...", 1) if($interactive_mode);
			PrintMessageToFile($session_log_handle, "Configuration override file for $input_directory_path$input_filename found, loading it...", 1) unless($interactive_mode);

			my $config_overridden = 0;
			my $config_override;
		
			# Load the local config
			$config_overridden = 1;

			unless($config_override = YAML::Tiny->read($override_config_file))
			{
				$config_overridden = 0;
				PrintMessage("WARNING: Couldn't process configuration override file.  Will use defaults", 0) if($interactive_mode);
				PrintMessageToFile($session_log_handle, "WARNING: Couldn't process configuration override file.  Will use defaults", 0) unless($interactive_mode)
			}

			if($config_overridden)
			{
				if(exists $config_override->[0]->{output_path})
				{
					$output_directory_path = $config_override->[0]->{output_path};

					PrintMessage("Output path overridden, output will go in $output_directory_path", 0) if($interactive_mode);
					PrintMessageToFile($session_log_handle, "Output path overridden, output will go in $output_directory_path", 0) unless($interactive_mode)
				}

				if(exists $config_override->[0]->{output_filename})
				{
					$output_filename = $config_override->[0]->{output_filename};
					PrintMessage("Output filename overridden, output file will be called $output_filename", 0) if($interactive_mode);
					PrintMessageToFile($session_log_handle, "Output filename overridden, output file will be called $output_filename", 0) unless($interactive_mode)
				}

				if(exists $config_override->[0]->{profile})
				{
					$profile_file = $config_override->[0]->{profile};
					PrintMessage("Encoding profile overridden, will use $profile_file instead.", 0) if($interactive_mode);
					PrintMessageToFile($session_log_handle, "Encoding profile overridden, will use $profile_file instead", 0) unless($interactive_mode)
				}

				if(exists $config_override->[0]->{title})
				{
					$output_title = $config_override->[0]->{title};
				}
                if(exists $config_override->[0]->{split_chapters})
                {
                    $output_chapters = $config_override->[0]->{split_chapters};
                }
			}
		}

		# Invoke the CLI
		my $encode_log_file = $global_configuration->[0]->{encode_log_path} . strftime("%d%b%Y-%I%M%S%p_$input_filename.txt", localtime);
		$files_processed++;

		PrintMessage("Beginning encode, encode log for this file will be saved as $encode_log_file", 1) if($interactive_mode);
		PrintMessageToFile($session_log_handle, "Beginning encode, encode log for this file will be saved as $encode_log_file", 1) unless($interactive_mode);

		my $return_status = undef;
		if(defined $output_chapters)
		{
			$return_status = run_handbrake::run("$input_directory_path$input_filename", "$output_directory_path$output_filename", $output_title, $profile_file, "$encode_log_file", "$output_chapters");
		}
		else
		{
			$return_status = run_handbrake::run("$input_directory_path$input_filename", "$output_directory_path$output_filename", $output_title, $profile_file, "$encode_log_file");
		}
		
		if($return_status != 0)
		{
			#my $new_filename = $orig_input_filename . ".BAD";
			#$input_filename =~ s/\\ / /g;
			#$input_filename =~ s/'/\\'/g; # Escape out single quotes
			#$input_filename =~ s/&/\\&/g; # Escape out ampersands
			#$input_filename =~ s/(\W)/\\$1/g; # Escape out all special characters
			my $new_filename = $input_filename . ".BAD";

			PrintMessage("WARNING: Encode for $input_filename failed!  Check log file for details!", 1) if($interactive_mode);
			PrintMessageToFile($session_log_handle, "WARNING: Encode for $input_filename failed!  Check log file for details!", 1) unless($interactive_mode);

			PrintMessage("WARNING: Renaming the file to $new_filename to get it out of the way.", 1) if($interactive_mode);
			PrintMessageToFile($session_log_handle, "WARNING: Renaming the file to $new_filename to get it out of the way.", 1) unless($interactive_mode);

			my $source_path = catfile($input_directory_path, $input_filename);
			my $dest_path = catfile($input_directory_path, $new_filename);
			if(!move($source_path, $dest_path))
			{
				PrintMessageToFile($session_log_handle, "WARNING: Couldn't rename $input_filename to $new_filename", 0);
			}
		}
		else
		{
			PrintMessage("Encode for $input_filename complete.", 1) if($interactive_mode);
			PrintMessageToFile($session_log_handle, "Encode for $input_filename complete.", 1) unless($interactive_mode);

			if($global_configuration->[0]->{on_complete} eq "rename")
			{
				##my $new_filename = $orig_input_filename . ".DONE";
				#$input_filename =~ s/\\ / /g;
				#$input_filename =~ s/'/\\'/g; # Escape out single quotes
				#$input_filename =~ s/&/\\&/g; # Escape out ampersands
				#$input_filename =~ s/(\W)/\\$1/g; # Escape out all special characters
				my $new_filename = $input_filename . ".DONE";

				PrintMessage("WARNING: Renaming the file to $new_filename to get it out of the way.", 1) if($interactive_mode);
				PrintMessageToFile($session_log_handle, "WARNING: Renaming the file to $new_filename to get it out of the way.", 1) unless($interactive_mode);

				my $source_path = catfile($input_directory_path, $input_filename);
				my $dest_path = catfile($input_directory_path, $new_filename);
				if(!move($source_path, $dest_path))
				{
					PrintMessageToFile($session_log_handle, "WARNING: Couldn't rename $input_filename to $new_filename", 0);
				}
			}
			else # delete
			{
				unlink "$input_directory_path$input_filename";
			}
		}
	}
	closedir(INPUT_DIR);
	
	if($files_processed == 0)
	{
		PrintMessage("WARNING: No input files with valid extensions detected.  Aborting.", 1) if($interactive_mode);
		PrintMessageToFile($session_log_handle, "WARNING: No input files with valid extensions detected.", 1) unless($interactive_mode);
	}
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

# Extracts the file extension from a filename
sub GetFileExtension
{
	if(scalar @_ != 1)
	{
		die "ERROR: You passed the wrong parameter set in to GetFileExtension";
	}
	
	my $filename = $_[0];
	my $index;
	
	for($index = length($filename); $index >= 0; $index--)
	{
		if(substr($filename, $index, 1) eq '.')
		{
			return substr($filename, $index);
		}
	}
}
