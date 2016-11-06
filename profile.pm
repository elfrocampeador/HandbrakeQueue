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

package profile;

use strict;
use warnings;

use YAML::Tiny;

sub parse {
    my $path = shift;
    my $profile = YAML::Tiny->read($path) or
        die("ERROR: Couldn't load the profile config file\n");
    return $profile->[0];
}

sub get_audio_tracks {
    my $profile = shift;
    my @audio_tracks;
    if( exists $profile->{audio}->{tracks}) {
        my @audio_tracks = $profile->{audio}->{tracks};
        return @audio_tracks;
    } else {
        return undef;
    }
}

sub get_audio_encoder {
    my $profile = shift;
    my $encoder = 'copy';
    if( exists $profile->{audio}->{encoder}) {
        $encoder = $profile->{audio}->{encoder};
    }
    return $encoder
}

sub get_video_encoder {
    my $profile = shift;
    my $encoder = 'x264';
    if( exists $profile->{video}->{encoder}) {
        $encoder = $profile->{video}->{encoder};
    }
    return $encoder
}

sub get_quality_factor {
    my $profile = shift;
    my $rf = 18;
    if( exists $profile->{video}->{quality}) {
        $rf = $profile->{video}->{quality}
    }
    return $rf
}

sub get_decomb {
    my $profile = shift;
    my $decomb = 0;
    if( exists $profile->{filters}->{decomb}) {
        my $decomb_str = $profile->{video}->{quality};
        if( lc $decomb_str == 'true') {
            $decomb = 1;
        }
    }
    return $decomb
}

sub get_subtitle_tracks {
    my $profile = shift;
    my @subtitle_tracks;
    if( exists $profile->{subtitle}->{tracks}) {
        my @subtitle_tracks = $profile->{subtitle}->{tracks};
        return @subtitle_tracks;
    } else {
        return undef;
    }
}
