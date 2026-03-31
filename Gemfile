# frozen_string_literal: true

source 'https://rubygems.org'

# Production gems
gem 'ruby-libgd', '~> 0.3.0'
gem 'octokit', '~> 9.0'
gem 'csv'

# Development and test gems
group :development, :test do
  gem 'rake'
  gem 'minitest', '~> 5.20'
  gem 'minitest-reporters', '~> 1.6'
  gem 'simplecov', '~> 0.22', require: false
  gem 'rubocop', '~> 1.50', require: false
  gem 'brakeman', '~> 6.0', require: false
  gem 'webmock', '~> 3.19'      # ← Agregar
  gem 'vcr', '~> 6.2'           # ← Agregar (opcional, para grabar respuestas)
end