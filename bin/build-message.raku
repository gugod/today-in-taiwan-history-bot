#!/usr/bin/env raku

sub MAIN (
    IO::Path(Str) :$data,  #= Path to data.
    Date(Str) :$today = Date.today, #= A date YYYY-MM-DD format that replaces today
) {
    say build-message(:$today, :$data);
    return 0;
}

sub build-message(Date :$today, IO::Path :$data) {
    my @records;

    my Str $mmdd = $today.yyyy-mm-dd("/").substr(5,5);

    for $data.dir(test => /^^ daily\-.+ \.tsv $$/) -> $tsvfile {
        @records.append: $tsvfile.lines.grep({ .substr(5,5) eq $mmdd });
    }

    my ($ymd, $body) = @records.pick(1).split(/\t/);
    my ($year, $month, $mday) = $ymd.split(/\//);

    return sprintf("#台灣 #歷史上的今天 #%d年%d月%d日\n%s", $year, $month, $mday, $body);
}
