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
