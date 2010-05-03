#!/usr/bin/perl -w
use strict;

while (<>) {
    chomp;
    next if /^\s*$/;
    $. == 1 and s/\xEF\xBB\xBF//;
    while(s/,\s+,/,,/g) {};
    s/,\s*$/,/;
    print "$_\n";
}
