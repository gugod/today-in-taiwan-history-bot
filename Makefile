all: data/daily-wikipedia.tsv

data/daily-wikipedia.tsv: bin/grok-wikipedia.pl
	perl ./bin/grok-wikipedia.pl > data/daily-wikipedia.tsv
