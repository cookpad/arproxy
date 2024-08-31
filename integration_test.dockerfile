FROM ruby:3.3

RUN apt-get update && apt-get install -y \
    libmariadb-dev \
    libpq-dev

COPY integration_test/Gemfile \
     integration_test/Appraisals \
     /app/

COPY integration_test/spec /app/spec/
COPY integration_test/gemfiles /app/gemfiles/

COPY lib /app/arproxy/lib/
COPY arproxy.gemspec /app/arproxy/arproxy.gemspec

WORKDIR /app

RUN bundle install
RUN bundle exec appraisal install
