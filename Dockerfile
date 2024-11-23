FROM ruby:3.3

WORKDIR /app

COPY lib lib
COPY spec spec
COPY gemfiles gemfiles

COPY arproxy.gemspec arproxy.gemspec
COPY Gemfile Gemfile
COPY Appraisals Appraisals
COPY .env .env
COPY .rspec .rspec

RUN apt update
RUN apt install --no-install-recommends -y build-essential freetds-dev

RUN bundle install
RUN bundle exec appraisal install

RUN mkdir -p /app/db/mysql
RUN ln -s /var/lib/mysql /app/db/mysql/data

# dummy command to keep the container running
CMD ["sleep", "infinity"]
