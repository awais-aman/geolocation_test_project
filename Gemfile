# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.2'

gem 'activerecord', '~> 7.2'
gem 'dotenv', groups: %i[development test]
gem 'faraday', '~> 2.9'
gem 'jwt', '~> 2.8'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.4'
gem 'rack-cors', '~> 2.0'
gem 'rake', '~> 13.2'
gem 'sinatra', '~> 4.0'
gem 'sinatra-contrib', '~> 4.0'

group :development, :test do
  gem 'factory_bot', '~> 6.4'
  gem 'rack-test', '~> 2.1'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.68', require: false
  gem 'rubocop-rspec', '~> 3.2', require: false
  gem 'simplecov', '~> 0.22', require: false
  gem 'webmock', '~> 3.23'
end
