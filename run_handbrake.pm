package run_handbrake;

use strict;
use warnings;

use File::Which qw(which);

=head1 NAME

HandbrakeQueue::run_handbrake - Run the HandBrakeCLI

=head3 find_handbrake_cli

    my $handbrake_avail = HandbrakeQueue::run_handbrake->find_handbrake_cli();

Check if the HandBrakeCLI executable can be found in the current PATH.

=cut

sub find_handbrake_cli {
    my $path;
    $path = which('HandBrakeCLI');
    if( ! defined $path) {
        return 0;
    }
    return 1;
}

=head3 run

    HandbrakeQueue::run_handbrake->run(
        $input_file, $output_file, $title, %config);

Actually run the HandBrakeCLI on a file.

=cut

sub run {
    my ($infile, $outfile, $title, %config) = @_;
    if( find_handbrake_cli() == 0) {
        die "ERROR: Can't find HandBrakeCLI executable in the PATH";
    }
    my @cmd_args = ('HandBrakeCLI', '-i', $infile, 't', $title, '-o', $outfile);
    # Default Encoder settings if none are defined
    push @cmd_args, '-e', 'x264', '-q', '18', '-E',
             'copy', join(',', %config{'audio_tracks'});
    # TODO(mtreinish): define a format for config and how to handle building an
    # arg list from it
    system(@cmd_args);
}
