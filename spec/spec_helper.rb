# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
    add_filter '/spec/'
    add_filter '/config/puma.rb'
    add_filter '/config/boot.rb'
    add_filter '/config/database.rb'
    add_filter '/db/migrate/'
    add_filter '/db/seeds.rb'
    add_filter '/lib/geolocator/provider.rb'
  end
end

ENV['RACK_ENV'] = 'test'
ENV['IPSTACK_ACCESS_KEY'] = 'test-ipstack-key'
require_relative '../config/boot'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |file| require file }
