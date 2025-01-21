FROM ruby:3.3.7-slim-bullseye

# Install necessary packages
RUN apt-get update -qq && apt-get install -y \
    nodejs \
    postgresql-client \
    build-essential \
    libgmp-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

# Install bundle dependencies
RUN bundle install

COPY . /app

# Set the entry point to the main Ruby script
CMD [ "ruby", "main.rb" ]

# Expose the port the app runs on
EXPOSE 4567