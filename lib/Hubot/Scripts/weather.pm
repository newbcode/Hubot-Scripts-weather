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
        my %current = condition_process($woeid, 'current');
        p %current;

    }
    else {
        $msg->send($woeid);
    }
}

sub condition_process {
    my ($woeid_param, $user_state) = @_; 
    my $ua = LWP::UserAgent->new;
    my %current;
    my %weekly;
    my %forecast;
    p $woeid_param;

    my $y_rep = $ua->get("http://weather.yahooapis.com/forecastrss?w=$woeid_param&u=c");
    
    if ($y_rep->is_success) {
        my $html = $y_rep->decoded_content;

        if ( $user_state eq 'current' ) {
            my ($condition, $temp, $date) = ($html =~ m{<yweather:condition  text="(\w+)"  code="4"  temp="(\d+)"  date="(.*?)" />}gsm);
            $current{condition} = $condition;
            $current{temp} = $temp;
            $current{date} = $date;
            my ($city, $country) = ($html =~ m{<yweather:location city="(.*?)" .*? country="(.*?)"/>}gsm); 
            $current{location} = "$country - $city";
            my ($chill, $direction, $speed) = ($html =~ m{<yweather:wind chill="(\d+)"   direction="(\d+)"   speed="(.*?)" />}gsm); 
            $current{chill} = $chill;
            $current{direction} = $direction;
            $current{speed} = $speed;
            my ($humidty, $visibility, $pressure, $rising) = ($html =~ m{<yweather:atmosphere humidity="(\d+)"  visibility="(\d+)"  pressure="(.*?)"  rising="(\d+)" />}gsm); 
            $current{humidty} = $humidty;
            $current{visibility} = $visibility;
            $current{pressure} = $pressure;
            $current{rising} = $rising;
            my ($sunrise, $sunset) = ($html =~ m{<yweather:astronomy sunrise="(.*?)"   sunset="(.*?)"/>}gsm); 
            $current{sunrise} = $sunrise;
            $current{sunset} = $sunset;

            return %current;
        }
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
