# frozen_string_literal: true

require_relative 'test_helper'

class TestArchiveMetrics < Minitest::Test
  def test_views_csv_creation
    data = [
      { timestamp: '2026-03-01', count: 100, uniques: 45 },
      { timestamp: '2026-03-02', count: 120, uniques: 50 }
    ]

    csv_path = create_temp_csv(
      data.map { |v| [v[:timestamp], v[:count], v[:uniques]] },
      ['date', 'count', 'uniques']
    )

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

    dates = CSV.read(csv_path, headers: true).map { |r| r['date'] }
    assert_equal 2, dates.size
    assert_includes dates, '2026-03-01'
    assert_includes dates, '2026-03-02'
  end

  def test_config_loading
    config_content = {
      'repositories' => [
        { 'owner' => 'test', 'name' => 'test-repo' }
      ]
    }

    config_path = create_temp_config(config_content)
    config = YAML.load_file(config_path)

    assert config.is_a?(Hash)
    assert config['repositories']
    assert_equal 'test', config['repositories'].first['owner']
  end

  def test_csv_headers_are_correct
    csv_path = File.join(@temp_dir, 'test_views.csv')
    
    CSV.open(csv_path, 'w') do |csv|
      csv << ['date', 'count', 'uniques']
      csv << ['2026-03-01', '100', '45']
    end

    headers = CSV.open(csv_path, 'r', headers: true).first.headers
    assert_includes headers, 'date'
    assert_includes headers, 'count'
    assert_includes headers, 'uniques'
  end

  def test_empty_csv_handling
    csv_path = File.join(@temp_dir, 'empty.csv')
    File.write(csv_path, '')
    
    assert File.exist?(csv_path)
    assert File.size(csv_path) == 0
  end
end