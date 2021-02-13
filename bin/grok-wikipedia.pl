#!/usr/bin/env perl
use v5.30;
use warnings;
use utf8;

use Mojo::UserAgent;
use JSON;

sub grok_wikipedia_annual_page {
    my ($url) = @_;
    my $ua = Mojo::UserAgent->new;
    my ($year) = $url =~ m{/wiki/ ([0-9]+) %E5%B9%B4%E8%87%BA%E7%81%A3 \z}x;

    my $res = $ua->get($url)->result;

    unless ($res->is_success) {
        die "Failed to fetch wikipedia page: $url";
    }

    $res->dom->at("#toc")->remove;
    $res->dom->find("sup.reference")->map('remove');

    my %section;
    my $section;
    $res->dom->at("#mw-content-text")->find("h2,li")->each(
        sub {
            my ($el) = @_;
            if ($el->tag eq "h2") {
                my $title = $el->at(".mw-headline")->all_text;
                $section = $section{$title} = { items => [] };
            } else {
                push @{$section->{items}}, $el->all_text;
            }
        }
    );

    for my $item (@{$section{"大事記"}{"items"}}) {
        next unless $item =~ m/(?<month>[0-9]+)月(?<mday>[0-9]+)日：(?<body>.+)/s;
        my $ymd = sprintf('%4d/%02d/%02d', $year, $+{'month'}, $+{'mday'});
        my $body = $+{'body'} =~ s/\p{XPosixCntrl}//gr =~ s/[\n\t]//sgr;

        say $ymd . "\t" . $body;
    }
}


grok_wikipedia_annual_page('https://zh.wikipedia.org/wiki/1897%E5%B9%B4%E8%87%BA%E7%81%A3');
