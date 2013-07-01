package Hubot::Scripts::weather;

use utf8;
use strict;
use warnings;
use LWP::UserAgent;
use Data::Printer;

sub load {
    my ( $class, $robot ) = @_;
 
    $robot->hear(
        qr/^weather weekly (.+)/i,    
        \&weekly_process,
    );
    $robot->hear(
        qr/^weather forecast (.+)/i,    
        \&fore_process,
    );
    $robot->hear(
        qr/^weather (.+)/i,    
        \&current_process,
    );
}

sub weekly_process {
}

sub forecast_process {
}

sub current_process {
    my $msg = shift;
    my $user_input = $msg->match->[0];

    woeid($user_input);
    
}

sub woeid {
    my $city = @_;
    p $city;
    my $ua = LWP::UserAgent->new;

    my $rep = $ua->get("http://woeid.rosselliot.co.nz/lookup/$city");
    
    if ($rep->is_success) {
        print $rep->decoded_content;
    }
    else {
        die $rep->status_line;
    }
}
    

1;

=pod

=head1 Name 

    Hubot::Scripts::weather
 
=head1 SYNOPSIS
 
    weather <city name>  - View current local area weather information. 
    weather weekly <city name> - View weekly local area weather information.
    weather weekly <city name1> <city name2>... - View weekly local areas weather information.
    weather forecast <local name> - View local weather forecast information. (ex: KangWon-Do, Gyeonggi-Do ..)

=head1 AUTHOR

    YunChang Kang <codenewb@gmail.com>
 
=cut
