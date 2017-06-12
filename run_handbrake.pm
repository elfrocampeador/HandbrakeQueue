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

package run_handbrake;

use strict;
use warnings;

use File::Which qw(which);

use profile;

=head1 NAME

run_handbrake - Run the HandBrakeCLI

=head3 find_handbrake_cli

    my $handbrake_avail = run_handbrake->find_handbrake_cli();

Check if the HandBrakeCLI executable can be found in the current PATH.

=cut

sub find_handbrake_cli
{
    my $path;
    $path = which('HandBrakeCLI');
    if(!defined $path)
	{
        return 0;
    }
    return 1;
}

=head3 run

    run_handbrake->run(
        $input_file, $output_file, $title, $profile_path);

Actually run the HandBrakeCLI on a file.

=cut

sub run
{
    my ($infile, $outfile, $title, $profile_path, $log_path, $output_chapters) = @_;
	
	if( find_handbrake_cli() == 0)
	{
        die "ERROR: Can't find HandBrakeCLI executable in the PATH";
    }
	
	if($^O ne "linux") # If we're not running on linux (assume Windows)
	{
		$infile = "\"$infile\"";
	}

    my @cmd_args = ('HandBrakeCLI', '-i', $infile, '-o',
                    $outfile);

    if(defined $title)
	{
        push @cmd_args, '-t', $title;
    } 
	else
	{
        push @cmd_args, '--main-feature';
    }
    if(defined $output_chapters)
	{
        push @cmd_args, '-c', $output_chapters
    }
    my $profile = profile::parse($profile_path);
    # Append video encoder option
    my $video_enc = profile::get_video_encoder($profile);
    push @cmd_args, '-e', $video_enc;
    # Append audio encoder option
    my $audio_enc = profile::get_audio_encoder($profile);
    push @cmd_args, '-E', $audio_enc;
    # Append video quality setting
    my $quality = profile::get_quality_factor($profile);
    push @cmd_args, '-q', $quality;
    # Append decomb
    if(profile::get_decomb($profile))
	{
        push @cmd_args, '-5';
    }
    # Append audio tracks
    my @audio_tracks = profile::get_audio_tracks($profile);
    if(@audio_tracks)
	{
        push @cmd_args, '--audio';
        push @cmd_args, join(',', @audio_tracks);
    }

    # Append audio track names
    my @audio_track_names = profile::get_audio_track_names($profile);
    if(@audio_track_names)
	{
        push @cmd_args, '--aname';
        push @cmd_args, join(',', @audio_track_names);
    }

    # Append subtitle tracks
    my @subtitle_tracks = profile::get_subtitle_tracks($profile);
    if(@subtitle_tracks)
	{
        push @cmd_args, '--subtitle';
        push @cmd_args, join(',', @subtitle_tracks);
    }

    # Append chapters
    if(profile::get_chapters($profile))
	{
        push @cmd_args, '-m';
    }

    # Append encoder preset
    my $encoder_preset = profile::get_video_encoder_preset($profile);
    if(defined $encoder_preset)
	{
        push @cmd_args, '--encoder-preset', $encoder_preset;
    }

    # Append encoder tune
    my $encoder_tune = profile::get_video_encoder_tune($profile);
    if(defined $encoder_tune)
	{
        push @cmd_args, '--encoder-tune', $encoder_tune;
    }

    # Run the command
    my $cmd_line = join(' ', @cmd_args);

    my $status = system($cmd_line . " 1>$log_path 2>&1");

    return $status;
}

1;
