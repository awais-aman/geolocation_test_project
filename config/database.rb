# frozen_string_literal: true

require 'active_record'
require 'erb'
require 'pg'
require 'uri'
require 'yaml'

module Database
  CONFIG_PATH = File.expand_path('database.yml', __dir__)

  module_function

  def connect!
    ensure_postgresql!
    ActiveRecord::Base.establish_connection(active_record_config)
    ActiveRecord::Base.connection
  end

  def env
    ENV.fetch('RACK_ENV', 'development')
  end

  def config
    @config = nil if @config_env != env
    return @config if @config

    @config_env = env
    @config = load_config
  end

  def load_config
    raise "Missing database configuration at #{CONFIG_PATH}" unless File.exist?(CONFIG_PATH)

    raw = ERB.new(File.read(CONFIG_PATH)).result
    yaml = YAML.safe_load(raw, aliases: true)
    defaults = yaml.fetch('default', {})
    environment = yaml.fetch(env) { raise "No database config for #{env} in database.yml" }

    defaults.merge(environment).transform_keys(&:to_s)
  end

  def active_record_config
    return parse_url_to_config(ENV.fetch('DATABASE_URL', nil)) if ENV['DATABASE_URL'].to_s.strip != ''

    cfg = config
    return parse_url_to_config(cfg['url']) if cfg['url'].to_s.strip != ''

    {
      adapter: 'postgresql',
      host: cfg.fetch('host'),
      port: cfg.fetch('port'),
      username: cfg.fetch('username'),
      password: cfg.fetch('password'),
      database: cfg.fetch('database'),
      pool: cfg.fetch('pool', 5)
    }
  end

  def parse_url_to_config(url)
    uri = URI.parse(url)
    {
      adapter: 'postgresql',
      host: uri.host,
      port: uri.port || 5432,
      username: uri.user,
      password: uri.password,
      database: uri.path.delete_prefix('/'),
      pool: config.fetch('pool', 5)
    }
  end

  def ensure_postgresql!
    cfg = active_record_config
    adapter = cfg[:adapter] || cfg['adapter']
    return if %w[postgresql postgres].include?(adapter.to_s)

    raise 'This application requires PostgreSQL (adapter: postgresql in config/database.yml).'
  end

  def database_name
    cfg = active_record_config
    cfg[:database] || cfg['database']
  end

  def maintenance_database
    config.fetch('maintenance_database', 'postgres')
  end

  def migrate!
    ActiveRecord::MigrationContext.new(File.join(ROOT, 'db', 'migrate')).migrate
  end

  def seed!
    load File.join(ROOT, 'db', 'seeds.rb')
  end

  def create_database!
    cfg = active_record_config
    conn = PG.connect(
      host: cfg[:host],
      port: cfg[:port],
      user: cfg[:username],
      password: cfg[:password],
      dbname: maintenance_database
    )
    exists = conn.exec_params('SELECT 1 FROM pg_database WHERE datname = $1', [database_name]).any?
    conn.exec("CREATE DATABASE #{PG::Connection.quote_ident(database_name)}") unless exists
    conn.close
  end
end
