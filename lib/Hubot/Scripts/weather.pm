package Hubot::Scripts::weather;

use utf8;
use strict;
use warnings;
use LWP::UserAgent;
use Data::Printer;
use Encode;

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
        qr/^weather (.+) (.+)/i,    
        \&current_process,
    );
}

sub weekly_process {
}

sub forecast_process {
}

sub current_process {
    my $msg = shift;
    my $user_country = $msg->match->[0];
    my $user_distric = $msg->match->[1];

    my $woeid = woeid_process($msg, $user_country, $user_distric);

    if ( $woeid ) {
        condition_process($woeid);
    }
    else {
        $msg->send($woeid);
    }
}

sub condition_process {
    my $woeid_param = shift; 
    my $ua = LWP::UserAgent->new;
    my %current;
    my %weekly;
    my %forecast;
    p $woeid_param;

    my $y_rep = $ua->get("http://weather.yahooapis.com/forecastrss?w=$woeid_param&u=c");
    
    if ($y_rep->is_success) {
        my $html = $y_rep->decoded_content;

        my ($city, $country) = ($html =~ m{<yweather:location city="(.*?)" .*? country="(.*?)"/>}gsm); 
        $current{location} = "$country - $city";
        p $current{location};
        my ($chill, $direction, $speed) = ($html =~ m{<yweather:wind chill="(\d+)" direction="(\d+)" speed="(.*?)"/>}gsm); 
        p $chill;
        p $direction;
        p $speed;
        $current{wind} = $chill;
        p $current{wind};

    }
    else {
        die $y_rep->status_line;
    }
}

sub woeid_process {
    my ($msg, $country, $distric) = @_; 
    my $param = "$country"." $distric";
    my $error_msg = 'The name of the country or the city name wrong.';

    my $ua = LWP::UserAgent->new;

    my $rep = $ua->get("http://woeid.rosselliot.co.nz/lookup/$param");
    
    if ($rep->is_success) {
         my @woeid = $rep->decoded_content =~ m{data-woeid="(\d+)"}gsm;

         if ( $woeid[1] ) {
            return "$error_msg";
         }
         elsif (!@woeid ) {
            return "$error_msg";
         }
         else {
             return $woeid[0];
         }
    }
    else {
        die $rep->status_line;
    }
}

1;

=pod

=head1 Name y

    Hubot::Scripts::weather
 
=head1 SYNOPSIS
 
    weather <city name>  - View current local area weather information. 
    weather weekly <city name> - View weekly local area weather information.
    weather weekly <city name1> <city name2>... - View weekly local areas weather information.
    weather forecast <local name> - View local weather forecast information. (ex: KangWon-Do, Gyeonggi-Do ..)

=head1 AUTHOR

    YunChang Kang <codenewb@gmail.com>
 
=cut
