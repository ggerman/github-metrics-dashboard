# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  coverage_dir 'coverage'
end

require 'minitest/autorun'
require 'minitest/reporters'
require 'webmock/minitest'
require 'vcr'
require 'tempfile'
require 'fileutils'

# Nice test output
Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new,
  Minitest::Reporters::SpecReporter.new
]

# VCR configuration for recording API calls
VCR.configure do |config|
  config.cassette_library_dir = 'test/cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_TOKEN'] || 'test-token' }
  config.allow_http_connections_when_no_cassette = false
end

# Helper methods for tests
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
end