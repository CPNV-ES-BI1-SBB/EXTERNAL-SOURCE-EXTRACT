FROM ruby:3.3.7-slim-bullseye

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libgmp-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN bundle install

COPY . /app

COPY .env /app/.env

CMD [ "ruby", "main.rb" ]

EXPOSE 4567