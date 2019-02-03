FROM ruby:latest

RUN apt-get update && apt-get install -y nodejs

COPY . /var/www/app
WORKDIR /var/www/app

RUN bundle install

CMD bin/start