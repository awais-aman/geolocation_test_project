# frozen_string_literal: true

ENV["RACK_ENV"] ||= "development"

require "bundler/setup"
Bundler.require(:default, ENV.fetch("RACK_ENV", "development").to_sym)

require "dotenv/load" if ENV["RACK_ENV"] == "development"

ROOT = File.expand_path("..", __dir__)

$LOAD_PATH.unshift(File.join(ROOT, "app"))
$LOAD_PATH.unshift(File.join(ROOT, "lib"))
$LOAD_PATH.unshift(ROOT)

require_relative "database"
Database.connect!
Database.migrate! if ENV["RACK_ENV"] == "test"

lib_files = Dir[File.join(ROOT, "lib", "**", "*.rb")].sort
provider_files = lib_files.select { |file| file.include?("/providers/") }
core_files = lib_files - provider_files
core_files.each { |file| require file }
provider_files.each { |file| require file }
app_files = Dir[File.join(ROOT, "app", "**", "*.rb")].sort
application_record = File.join(ROOT, "app", "models", "application_record.rb")
require application_record if app_files.include?(application_record)
app_files.each { |file| require file unless file == application_record }

require_relative "dependencies"
require_relative "../api/swagger"
require_relative "../api/v1/auth"
require_relative "../api/v1/geolocations"
require_relative "../api/application"
