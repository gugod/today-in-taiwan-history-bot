#!/usr/bin/env perl
use v5.30;
use warnings;
use utf8;
use autodie;
use feature 'signatures';
no warnings 'experimental::signatures';

use Mojo::UserAgent;

sub comb ($regex, $str) {
    my @r = $str =~ /($regex)/g;
    return @r;
}

## main
my $ua = Mojo::UserAgent->new;
my $res = $ua->get('https://ja.wikipedia.org/wiki/%E6%AC%A7%E9%99%BD%E8%8F%B2%E8%8F%B2')->result;
my $dom = $res->dom;
$dom->find('sup')->map('remove');

my @records = $dom->find('table.wikitable tr')->grep(
    sub {
        $_->children("td")->size() == 8;
    }
)->map(
    sub ($el) {
        my $s = $el->at('td:nth-child(2)')->all_text;
        my ($year, $month, $mday) = comb qr/[0123456789]+/, $s;
        return unless defined($mday);

        my $date = sprintf('%4d/%02d/%02d', $year, $month, $mday);
        my $title = $el->at('td:nth-child(4)')->all_text() =~ s/[\n\t]//grs;
        return [ $date, $title ];
    }
)->each;

my $output_file = "data/daily-feifei-album-releases.tsv";
open my $output_fh, ">:utf8", $output_file;

binmode STDOUT, ":utf8";
for (@records) {
    my ($date, $title) = @$_;
    my $gist = "歐陽菲菲單曲〈${title}〉發行";
    print $output_fh "${date}\t${gist}\n";
}
close($output_fh);
say "DONE: ${output_file}";
