#!/usr/bin/perl 

use strict;
use warnings;

my $CONFIG_NAME = ".config" unless $ARGV[0];
my $HEADER_NAME = "config.h" unless $ARGV[1];

my $TIME = localtime(time());
my $out_header = <<EOH;
/****************************************************
                   DO NOT EDIT! 
   Automatically generated by 'scripts/genconfig.pl'
              $TIME
*****************************************************/

EOH

open(CONF, '<' . $CONFIG_NAME) or die "You must run the \'make config\'!";
open(HEADER, '>' . $HEADER_NAME) or die "Cannot create $HEADER_NAME: $!";

print HEADER $out_header;

while (<CONF>) {
    if (/^#/ or $_ eq "") {
        next;
    } elsif (/(.+)=(.+)/) {
        if ($2 eq "y") {
            print HEADER "#define $1\n"
        } else {
            print HEADER "#define $1 $2\n";
        }
    }
}

close CONF;
close HEADER;