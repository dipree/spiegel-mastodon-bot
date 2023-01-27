FROM ruby:3.1.3
COPY Gemfile* ./
RUN bundle install
COPY . .
ENTRYPOINT ["ruby", "app.rb"]