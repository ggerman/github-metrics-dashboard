# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  coverage_dir 'coverage'
end

require 'minitest/autorun'
require 'minitest/reporters'
require 'fileutils'
require 'csv'
require 'tempfile'
require 'webmock/minitest'
require 'vcr'

# Configuración de reportes de Minitest (output más lindo)
Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new,
  Minitest::Reporters::SpecReporter.new
]

# ================================================================
# Configuración de VCR (graba y reproduce respuestas HTTP reales)
# ================================================================
VCR.configure do |config|
  # Dónde guardar las "grabaciones" (cassettes)
  config.cassette_library_dir = 'test/cassettes'

  # Usar WebMock como adaptador HTTP
  config.hook_into :webmock

  # Ocultar información sensible en los cassettes
  config.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_TOKEN'] || 'test-token' }
  config.filter_sensitive_data('<GITHUB_USER>') { ENV['GITHUB_USER'] || 'test-user' }

  # Permitir conexiones HTTP reales cuando no hay cassette
  # (útil para grabar por primera vez)
  config.allow_http_connections_when_no_cassette = true

  # Ignorar ciertas URLs (ej: localhost, coverage)
  config.ignore_localhost = true

  # Formato de los cassettes (JSON es más legible)
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri, :body]
  }
end

# ================================================================
# Helper methods para todos los tests
# ================================================================

module TestHelper
  # Retorna la ruta a un archivo en test/fixtures/
  def fixture_path(filename)
    File.join(File.dirname(__FILE__), 'fixtures', filename)
  end

  # Carga el contenido de un fixture
  def load_fixture(filename)
    File.read(fixture_path(filename))
  end

  # Crea un archivo CSV temporal con datos
  def create_temp_csv(data, headers)
    temp = Tempfile.new(['test', '.csv'])
    CSV.open(temp.path, 'w') do |csv|
      csv << headers
      data.each { |row| csv << row }
    end
    temp.path
  end

  # Crea un archivo YAML temporal con configuración
  def create_temp_config(repos)
    temp = Tempfile.new(['config', '.yml'])
    temp.write(repos.to_yaml)
    temp.close
    temp.path
  end

  # Ejecuta un bloque con una variable de entorno temporal
  def with_env(key, value)
    old_value = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = old_value
  end

  # Ejecuta un bloque grabado con VCR
  def with_vcr(cassette_name, &block)
    VCR.use_cassette(cassette_name, &block)
  end
end

# ================================================================
# Incluir helpers en todos los tests
# ================================================================

class Minitest::Test
  include TestHelper

  # Setup que corre antes de cada test
  def setup
    @temp_dir = Dir.mktmpdir
  end

  # Teardown que corre después de cada test
  def teardown
    FileUtils.remove_entry @temp_dir
  end
end
