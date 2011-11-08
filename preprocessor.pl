#!/usr/bin/perl -w
use strict;

while (<>) {
    chomp;
    $. == 1 and s/\xEF\xBB\xBF//;
    s/\s*,\s*/,/g;
    s/\r\n|\n|\r//g;
    next if /^\s*$/;
    print "$_\r\n";
}
