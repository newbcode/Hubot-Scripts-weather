package Hubot::Scripts::weather;

use utf8;
use strict;
use warnings;
use Data::Printer;

sub load {
    my ( $class, $robot ) = @_;
 
    $robot->hear(
        qr/^weather weekly (.+)/i,    
        \&city_process,
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

sub city_process {
}

sub fore_process {
}

sub current_process {
    my $msg = shift;
    my $user_input = $msg->match->[0];
    
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
