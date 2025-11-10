# frozen_string_literal: true

source 'https://rubygems.org'

# Web framework (http://sinatrarb.com)
gem 'rackup', '~> 2.2'
gem 'sinatra', '~> 4.0'

# Logging
gem 'logger', '~> 1.6'

group :development do
  # Code formatting & linting
  gem 'rubocop', '~> 1.22', require: false
  gem 'rubocop-rspec', '~> 3.2', require: false

  # Sinatra utilities (e.g. live reload)
  gem 'sinatra-contrib', '~> 4.0'
end

group :production do
  # Ruby web server (https://puma.io)
  gem 'puma', '~> 7.0'
end

group :test do
  gem 'nokogiri', '~> 1.16'
  gem 'rack-test', '~> 2.1'
  gem 'rspec', '~> 3.13'
  gem 'simplecov', '~> 0.22.0', require: false
end
