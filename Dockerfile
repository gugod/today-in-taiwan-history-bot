FROM perl:5.32
WORKDIR /app
COPY . /app
RUN cpanm --no-man-pages -n -q --installdeps .
CMD ["perl", "bin/tweet.pl"]
