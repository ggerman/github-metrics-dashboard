# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  coverage_dir 'coverage'
end

# ================================================================
# PRIMERO: Requerir Minitest (esto es lo que faltaba)
# ================================================================
require 'minitest/autorun'
require 'minitest/reporters'
require 'fileutils'
require 'csv'
require 'tempfile'

# ================================================================
# Recién después configuramos los reporters
# ================================================================
Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new,
  Minitest::Reporters::SpecReporter.new
]

# ================================================================
# Opcional: webmock y vcr solo si están instalados
# ================================================================
begin
  require 'webmock/minitest'
  require 'vcr'
  
  VCR.configure do |config|
    config.cassette_library_dir = 'test/cassettes'
    config.hook_into :webmock
    config.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_TOKEN'] || 'test-token' }
    config.filter_sensitive_data('<GITHUB_USER>') { ENV['GITHUB_USER'] || 'test-user' }
    config.allow_http_connections_when_no_cassette = true
    config.ignore_localhost = true
    config.default_cassette_options = {
      record: :new_episodes,
      match_requests_on: [:method, :uri, :body]
    }
  end
rescue LoadError
  puts "WebMock/VCR not available, skipping HTTP mocking"
end

# ================================================================
# Helper methods para todos los tests
# ================================================================

module TestHelper
  def fixture_path(filename)
    File.join(File.dirname(__FILE__), 'fixtures', filename)
  end

  def load_fixture(filename)
    File.read(fixture_path(filename))
  end

  def create_temp_csv(data, headers)
    temp = Tempfile.new(['test', '.csv'])
    CSV.open(temp.path, 'w') do |csv|
      csv << headers
      data.each { |row| csv << row }
    end
    temp.path
  end

  def create_temp_config(repos)
    temp = Tempfile.new(['config', '.yml'])
    temp.write(repos.to_yaml)
    temp.close
    temp.path
  end

  def with_env(key, value)
    old_value = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = old_value
  end

  def with_vcr(cassette_name, &block)
    if defined?(VCR)
      VCR.use_cassette(cassette_name, &block)
    else
      yield
    end
  end
end

# ================================================================
# Configuración de tests
# ================================================================

class Minitest::Test
  include TestHelper

  def setup
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    if @temp_dir && Dir.exist?(@temp_dir)
      FileUtils.remove_entry @temp_dir
    end
  end
end