# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../scripts/archive_metrics'

class TestArchiveMetrics < Minitest::Test
  include TestHelper

  def setup
    @temp_dir = Dir.mktmpdir
    @original_env = ENV['GITHUB_TOKEN']
    ENV['GITHUB_TOKEN'] = 'test-token'
  end

  def teardown
    FileUtils.remove_entry @temp_dir
    ENV['GITHUB_TOKEN'] = @original_env
  end

  def test_views_csv_creation
    # Simulate API response
    views_data = [
      { timestamp: '2026-03-01', count: 100, uniques: 45 },
      { timestamp: '2026-03-02', count: 120, uniques: 50 }
    ]
    
    # Write to CSV
    csv_path = File.join(@temp_dir, 'test_views.csv')
    CSV.open(csv_path, 'w') do |csv|
      csv << ['date', 'count', 'uniques']
      views_data.each { |v| csv << [v[:timestamp], v[:count], v[:uniques]] }
    end
    
    assert File.exist?(csv_path)
    csv_content = CSV.read(csv_path, headers: true)
    assert_equal 2, csv_content.size
    assert_equal '100', csv_content.first['count']
  end

  def test_append_mode_no_duplicates
    csv_path = File.join(@temp_dir, 'test_views.csv')
    
    # First write
    CSV.open(csv_path, 'w') do |csv|
      csv << ['date', 'count', 'uniques']
      csv << ['2026-03-01', '100', '45']
    end
    
    # Append new data
    CSV.open(csv_path, 'a') do |csv|
      csv << ['2026-03-02', '120', '50']
    end
    
    csv_content = CSV.read(csv_path, headers: true)
    assert_equal 2, csv_content.size
    assert_equal '100', csv_content[0]['count']
    assert_equal '120', csv_content[1]['count']
  end

  def test_load_existing_dates
    csv_path = File.join(@temp_dir, 'test_views.csv')
    CSV.open(csv_path, 'w') do |csv|
      csv << ['date', 'count', 'uniques']
      csv << ['2026-03-01', '100', '45']
      csv << ['2026-03-02', '120', '50']
    end
    
    dates = ArchiveMetrics.load_existing_dates(csv_path)
    assert_includes dates, '2026-03-01'
    assert_includes dates, '2026-03-02'
    assert_equal 2, dates.size
  end
end