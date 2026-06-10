# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'
require 'dotenv/load' if ENV['RACK_ENV'] == 'development'

ROOT = File.expand_path(__dir__)

Dir.glob(File.join(ROOT, 'lib', 'tasks', '**', '*.rake')).each { |task| load task }

task :db_connection do
  require_relative 'config/database'
  Database.connect!
end

task :environment do
  require_relative 'config/boot'
end

namespace :db do
  desc 'Create database (PostgreSQL must be running)'
  task :create do
    require_relative 'config/database'
    Database.create_database!
    puts "Database #{Database.database_name} ready."
  end

  desc 'Run pending migrations'
  task migrate: :db_connection do
    Database.migrate!
    puts 'Migrations complete.'
  end

  desc 'Load sample geolocation records (idempotent)'
  task seed: :environment do
    Database.seed!
  end

  desc 'Create, migrate, and seed'
  task setup: %i[create migrate seed]
end

desc 'Run the test suite'
task spec: :environment do
  sh 'bundle exec rspec'
end

desc 'Run the test suite with coverage report'
task coverage: :environment do
  ENV['COVERAGE'] = 'true'
  sh 'bundle exec rspec'
end

namespace :auth do
  desc 'Reset default API client and print new credentials (development only)'
  task reset_credentials: :environment do
    abort 'Not allowed in production' if ENV['RACK_ENV'] == 'production'

    ApiClient.find_by(name: 'default')&.destroy
    _client, client_secret = ApiClient.register!(name: 'default')

    puts 'client_id:     default'
    puts "client_secret: #{client_secret}"
  end
end

task default: :spec
