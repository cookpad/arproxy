FROM ruby:3.3

RUN apt-get update && apt-get install -y \
    libmariadb-dev \
    libpq-dev

COPY integration_test/Gemfile integration_test/Gemfile.lock /app/
COPY integration_test/spec /app/spec/

COPY lib /app/arproxy/lib/
COPY arproxy.gemspec /app/arproxy/arproxy.gemspec

WORKDIR /app
RUN bundle install
