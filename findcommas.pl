#!/usr/bin/perl -w
use strict;

while (<>) {
    s/^\xEF\xBB\xBF//;
    s/("[^"]*?),([^"]*?")/$1 - $2/g;
    print;
}
