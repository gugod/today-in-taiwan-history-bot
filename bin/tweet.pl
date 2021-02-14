#!/usr/bin/env perl
use v5.32;
use utf8;
use feature 'signatures';

use Twitter::API;
use YAML;
use DateTime;
use Path::Tiny;
use Encode ('encode_utf8');
use Getopt::Long ('GetOptionsFromArray');

sub main {
    my @args = @_;

    my %opts;
    GetOptionsFromArray(
        \@args,
        \%opts,
        'fake-today=s',
        'github-secret',
        'data=s',
        'c=s',
        'y|yes'
    ) or die("Error in arguments, but I'm not telling you what it is.");

    unless (-d $opts{'data'}) {
        die "Paramater `--data <path>` has to be a directory with a bunch of tsvs";
    }

    my $today = $opts{"fake-today"} ? DateTime_from_ymd( $opts{"fake-today"} ) : DateTime->now( time_zone => 'Asia/Taipei' )->truncate( to => 'day' );

    my $msg = build_message({ today => $today, data => $opts{'data'} });
    maybe_tweet_update(\%opts, $msg);

    return 0;
}

exit(main(@ARGV));

sub DateTime_from_ymd ($s) {
    my @ymd = split /[\/\-]/, $s;

    if (@ymd != 3) {
        die "Unknown date format in '$s'. Try something like: 2020/01/11";
    }

    return DateTime->new(
        year      => $ymd[0],
        month     => $ymd[1],
        day       => $ymd[2],
        hour      => '0',
        minute    => '0',
        second    => '0',
        time_zone => 'Asia/Taipei',
    );
}

sub build_message ($opts) {
    my $msg = "";
    my $today = $opts->{'today'};
    my $today_re = sprintf('[0-9]+/%02d/%02d', $today->month, $today->mday);

    my @records;
    for my $path (path($opts->{'data'})->children(qr/\Adaily-.+\.tsv\z/)) {
        next unless $path->is_file;
        push @records, grep { /\A${today_re}\t/ } split /\n+/, $path->slurp_utf8;
    }

    @records = grep { length($_) < 100 } @records;

    if (@records > 0) {
        my ($ymd, $body) = split /\t/, $records[rand(@records)];
        my ($year, $month, $mday) = split /\//, $ymd;
        $msg = sprintf('#歷史上的今天 [%d 年 %d 月 %d 日] %s', $year, $month, $mday, $body);
    }

    return $msg;
}

sub maybe_tweet_update ($opts, $msg) {
    unless ($msg) {
        say "# Message is empty.";
        return;
    }

    my $config;

    if ($opts->{c} && -f $opts->{c}) {
        say "[INFO] Loading config from $opts->{c}";
        $config = YAML::LoadFile( $opts->{c} );
    } elsif ($opts->{'github-secret'} && $ENV{'TWITTER_TOKENS'}) {
        say "[INFO] Loading config from env";
        $config = YAML::Load($ENV{'TWITTER_TOKENS'});
    } else {
        say "[INFO] No config.";
    }

    say "# Message";
    say "-------8<---------";
    say encode_utf8($msg);
    say "------->8---------";

    if ($opts->{y} && $config) {
        say "#=> Tweet for real";
        my $twitter = Twitter::API->new_with_traits(
            traits => "Enchilada",
            consumer_key        => $config->{consumer_key},
            consumer_secret     => $config->{consumer_secret},
            access_token        => $config->{access_token},
            access_token_secret => $config->{access_token_secret},
        );

        my $r = $twitter->update($msg);
        say "https://twitter.com/jabbot/status/" . $r->{id_str};
    } else {
        say "#=> Not tweeting";
    }
}
