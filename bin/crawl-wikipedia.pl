#!/usr/bin/env perl
use v5.30;
use warnings;
use utf8;
use feature 'signatures';
use autodie;

use Mojo::UserAgent;
use JSON;

sub grok_wikipedia_annual_page ($url) {
    my $ua = Mojo::UserAgent->new;
    my ($year) = $url =~ m{/wiki/ ([0-9]+) %E5%B9%B4%E8%87%BA%E7%81%A3 \z}x;

    my $res = $ua->get($url)->result;

    unless ($res->is_success) {
        die "Failed to fetch wikipedia page: $url";
    }

    $res->dom->find("sup.reference, #toc, h1#firstHeading")->map('remove');

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

    my @records;

    for my $item (@{$section{"大事記"}{"items"}}) {
        next unless $item =~ m/(?<month>[0-9]+) 月 (?<mday>[0-9]+) 日 (（.月..）)? (——|：) (?<body>.+)/sx;
        my $ymd = sprintf('%4d/%02d/%02d', $year, $+{'month'}, $+{'mday'});
        my $body = $+{'body'} =~ s/\p{XPosixCntrl}//gr =~ s/[\n\t]//sgr;

        push @records, [ $ymd, $body ];
    }

    return \@records;
}

for my $year (1894..2020) {
    my $output_file = "data/daily-wikipedia-${year}.tsv";
    next if -f $output_file;

    open my $output_fh, ">:utf8", $output_file;

    my $url = 'https://zh.wikipedia.org/wiki/' . $year . '%E5%B9%B4%E8%87%BA%E7%81%A3';
    my $records = eval { grok_wikipedia_annual_page($url) } // [];

    for my $it (@$records) {
        say $output_fh join("\t", @$it);
    }

    close($output_fh);
    say "DONE: $output_file";
}
