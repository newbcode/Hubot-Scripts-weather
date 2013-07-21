package Hubot::Scripts::weather;
# ABSTRACT: Weather Script for Hubot. 

use utf8;
use strict;
use warnings;
use LWP::UserAgent;
use Data::Printer;
use Encode;

sub load {
    my ( $class, $robot ) = @_;
 
    $robot->hear(
        qr/^forecast (.+)/i,    
        \&forecast_process,
    );
    $robot->hear(
        qr/^weather (.+)/i,    
        \&current_process,
    );
    $robot->hear(
        qr/^(\d+)/i,    
        \&station,
    );
}

sub forecast_process {
    my $msg = shift;
    my $user_country = $msg->match->[0];

    my $woeid = woeid_process($msg, $user_country);

    if ( $woeid =~ /^\d+/) {
        my @weekly = condition_process($woeid, 'weekly');
        $msg->send("[$weekly[0]"." $weekly[1]]"." Low/High[$weekly[2]℃ /$weekly[3]℃ ]"." Condition[$weekly[4]]");
        $msg->send("[$weekly[5]"." $weekly[6]]"." Low/High[$weekly[7]℃ /$weekly[8]℃ ]"." Condition[$weekly[9]]");
        $msg->send("[$weekly[10]"." $weekly[11]]"." Low/High[$weekly[12]℃ /$weekly[13]℃ ]"." Condition[$weekly[14]]");
        $msg->send("[$weekly[15]"." $weekly[16]]"." Low/High[$weekly[17]℃ /$weekly[18]℃ ]"." Condition[$weekly[19]]");
        $msg->send("[$weekly[20]"." $weekly[21]]"." Low/High[$weekly[22]℃ /$weekly[23]℃ ]"." Condition[$weekly[24]]");
    }
    else {
        $msg->send($woeid);
    }
}

sub current_process {
    my $msg = shift;
    my $user_country = $msg->match->[0];

    my $woeid = woeid_process($msg, $user_country);

    if ( $woeid =~ /^\d+/) {
        my %current = condition_process($woeid, 'current');
        $msg->send("$current{location}"."[ LastTime:$current{date} ]");
        $msg->send("The status of current weather-[$current{condition}]"." temp-[$current{temp}℃ ]"." humidity-[$current{humidty}%]" .
               " direction- [$current{direction}km]"." speed-[$current{speed}km/h]"." sunrise/sunset-[$current{sunrise}/$current{sunset}]");
    }
    else {
        $msg->send($woeid);
    }
}

sub condition_process {
    my ($woeid_param, $user_state) = @_; 
    my $ua = LWP::UserAgent->new;
    my %current;
    my @weekly;

    my $y_rep = $ua->get("http://weather.yahooapis.com/forecastrss?w=$woeid_param&u=c");
    
    if ($y_rep->is_success) {
        my $html = $y_rep->decoded_content;

        if ( $user_state eq 'current' ) {
            my ($condition, $temp, $date) = ($html =~ m{<yweather:condition  text="(.*?)"  code="\d+"  temp="(.*?)"  date="(.*?)" />}gsm);
            $current{condition} = $condition;
            $current{temp} = $temp;
            $current{date} = $date;
            my ($city, $country) = ($html =~ m{<yweather:location city="(.*?)" .*? country="(.*?)"/>}gsm); 
            $current{location} = "$country - $city";
            my ($chill, $direction, $speed) = ($html =~ m{<yweather:wind chill="(.+)"   direction="(.+)"   speed="(.*?)" />}gsm); 
            $current{chill} = $chill;
            $current{direction} = $direction;
            $current{speed} = $speed;
            my ($humidty, $visibility, $pressure, $rising) = ($html =~ m{<yweather:atmosphere humidity="(.+)"  visibility="(.*?)"  pressure="(.*?)"  rising="(.*?)" />}gsm); 
            $current{humidty} = $humidty;
            $current{visibility} = $visibility;
            $current{pressure} = $pressure;
            $current{rising} = $rising;
            my ($sunrise, $sunset) = ($html =~ m{<yweather:astronomy sunrise="(.*?)"   sunset="(.*?)"/>}gsm); 
            $current{sunrise} = $sunrise;
            $current{sunset} = $sunset;

            return %current;
        }
        elsif ( $user_state eq 'weekly' ) {
            my @weekly =  $html =~ m{<yweather:forecast day="(.*?)" date="(.*?)" low="(.*?)" high="(.*?)" text="(.*?)" code="\d+" />}gsm; 
            return @weekly;
        }

    }
    else {
        die $y_rep->status_line;
    }
}

sub woeid_process {
    my ($msg, $country) = @_; 
    my $param = "$country";
    my $error_msg = 'The name of the country or the city name wrong.';

    my $ua = LWP::UserAgent->new;

    my $rep = $ua->get("http://woeid.rosselliot.co.nz/lookup/$param");
    
    if ($rep->is_success) {
         my @woeid = $rep->decoded_content =~ m{data-woeid="(\d+)"}gsm;
         my @countrys = $rep->decoded_content =~ m{data-woeid="\d+"><td>.*?</td><td>.*?</td><td>(.*?)</td>}gsm;

         if ( $countrys[0] || $countrys[1]) {
            return "$woeid[0]";
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

sub station {
    my $msg = shift;
    my $user_ip = $msg->match->[0];

    $msg->http("http://www.ip2location.com/$user_ip")->get (
        sub {
            my ($body, $hdr) = @_;

            return if ( !$body || $hdr->{Status} !~ /^2/ );

            my $decoded_body = decode("utf8", $body);
#if ( $decoded_body =~ m{<td><b>Weather Station</b></td>.*?<td>(.*?)</td>}gsm ) {
            p $decoded_body;
                if ( $decoded_body =~ m{<td><b>(Weather Station)</b></td>} ) {
                    print $1;
                }
            }
        );
}

1;

=pod

=head1 SYNOPSIS

    Returns weather information from Yahoo Weather APIs!
 
    weather <country> <city> - View current local area weather information. (ex: weather <south korea> <kangnam>)
    forecast <country> <city> - View local weather forecast information. (ex: weather <south korea> <kangnam>) 

=cut
