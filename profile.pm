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
	
	my $profile = undef;
	
	eval
	{
		$profile = YAML::Tiny->read($path);
	} or do
	{
		die("ERROR: Error encountered while loading the profile config file.\nError message was: $@\n");
	};
	
    return $profile->[0];
}

sub get_audio_tracks {
    my $profile = shift;
    my @audio_tracks;

    if( exists $profile->{audio}->{tracks}) {
        @audio_tracks = (@{$profile->{audio}->{tracks}});
    }
    return @audio_tracks;
}

sub get_audio_track_names {
    my $profile = shift;
    my @audio_track_names;
    
    if( exists $profile->{audio}->{track_names}) {
        @audio_track_names = (@{$profile->{audio}->{track_names}});
    }
    return @audio_track_names;
}

sub get_audio_encoder {
    my $profile = shift;
    my $encoder = 'copy';
    if( exists $profile->{audio}->{encoder}) {
        $encoder = $profile->{audio}->{encoder};
    }
    return $encoder;
}

sub get_video_encoder {
    my $profile = shift;
    my $encoder = 'x264';
    if( exists $profile->{video}->{encoder}) {
        $encoder = $profile->{video}->{encoder};
    }
    return $encoder;
}

sub get_quality_factor {
    my $profile = shift;
    my $rf = 18;
    if( exists $profile->{video}->{quality}) {
        $rf = $profile->{video}->{quality}
    }
    return $rf;
}

sub get_decomb {
    my $profile = shift;
    my $decomb = 0;
    if( exists $profile->{filters}->{decomb}) {
        my $decomb_str = $profile->{filters}->{decomb};
        if( lc $decomb_str eq 'true') {
            $decomb = 1;
        }
    }
    return $decomb;
}

sub get_subtitle_tracks {
    my $profile = shift;
    my @subtitle_tracks;
    if( exists $profile->{subtitle}->{tracks}) {
        @subtitle_tracks = (@{$profile->{subtitle}->{tracks}});
    }
    return @subtitle_tracks;
}

sub get_chapters {
    my $profile = shift;
    my $chapters = 1;
    if( exists $profile->{chapters}) {
        my $chapter_str = $profile->{chapters};
        if( lc $chapter_str eq 'false') {
            $chapters = 0;
        }
    }
    return $chapters;
}

sub get_video_encoder_preset {
    my $profile = shift;
    my $encoder_preset = undef;
    if( exists $profile->{video}->{encoder_preset}) {
        $encoder_preset = $profile->{video}->{encoder_preset};
    }
    return $encoder_preset;
}

sub get_video_encoder_tune {
    my $profile = shift;
    my $encoder_tune = undef;
    if( exists $profile->{video}->{encoder_tune}) {
        $encoder_tune = $profile->{video}->{encoder_tune};
    }
    return $encoder_tune;
}

1;
