# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb'].exclude('test/test_helper.rb')
  t.verbose = true
  t.warning = false
end

task default: :test