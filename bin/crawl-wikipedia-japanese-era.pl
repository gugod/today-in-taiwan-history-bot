#!/usr/bin/env perl
use v5.30;
use warnings;
use utf8;
use autodie;
use feature 'signatures';
no warnings 'experimental::signatures';

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;
my $res = $ua->get('https://zh.wikipedia.org/wiki/日治台灣歷史年表')->result;
die $res->message if $res->is_error;

my $dom = $res->dom;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my @rec;
$dom->find("sup")->map('remove');
$dom->find('#mw-content-text h3')->each(
    sub {
        my $el = $_;
        my $t = $el->all_text;
        return unless $t =~ /([0-9]{4})年/;
        my $year = $1;
        my $list = $el->next;

        for my $it ($list->find("li")->map(sub { $_->all_text })->each) {
            my ($month, $date, $gist) = $it =~ m/^([0-9]+)月([0-9]+)日[，：](.+)$/;

            if (defined($month)) {
                push @rec, [
                    sprintf('%04d/%02d/%02d', $year, $month, $date),
                    $gist
                ];
            } else {
                say STDERR "Weird item: $it";
            }

        }
    });

open my $out, ">:utf8", "data/daily-wikipedia-japanese-era.tsv";
for my $it (@rec) {
    say $out join("\t", @$it);
}
close($out);
