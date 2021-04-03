use v5.32;
use utf8;
use feature 'signatures';

use Twitter::API;
use YAML;
use DateTime;
use Path::Tiny;
use Encode ('encode_utf8');
use Getopt::Long ('GetOptionsFromArray');

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

sub main {
    my @args = @_;

    my %opts;
    GetOptionsFromArray(
        \@args,
        \%opts,
        'data=s',
    ) or die("Error in arguments, but I'm not telling you what it is.");

    unless (-d $opts{'data'}) {
        die "Paramater `--data <path>` has to be a directory with a bunch of tsvs";
    }

    my %stats;
    for my $path (path($opts{'data'})->children(qr/\Adaily-.+\.tsv\z/)) {
        next unless $path->is_file;
        for my $line ($path->lines_utf8) {
            my ($year, $month, $date) = split /\//, substr($line, 0, 10);
            my $bucket = $month . "/" . $date;
            $stats{$bucket}++;
        }
    }
    for my $bucket (sort { $a cmp $b } keys %stats) {
        say $bucket . " => " . $stats{$bucket};
    }
}

exit(main(@ARGV));
