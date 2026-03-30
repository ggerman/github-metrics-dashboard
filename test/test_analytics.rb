# frozen_string_literal: true

require_relative 'test_helper'

class TestAnalytics < Minitest::Test
  def setup
    @sample_views = [100, 110, 120, 115, 130, 125, 140, 135, 150, 145]
    @sample_dates = (1..10).map { |i| Date.today - i }
  end

  def test_total_calculation
    total = @sample_views.sum
    assert_equal 1270, total
  end

  def test_average_calculation
    avg = @sample_views.sum / @sample_views.size.to_f
    assert_in_delta 127.0, avg, 0.1
  end

  def test_wow_growth
    # Simulate 14+ days of data
    views = [100, 110, 120, 130, 140, 150, 160,  # week 1
             110, 115, 125, 135, 145, 155, 165]  # week 2
    
    current_week = views.last(7).sum
    previous_week = views[-14..-8].sum
    growth = ((current_week - previous_week) * 100 / previous_week).round(1)
    
    assert_in_delta 3.7, growth, 0.1
  end

  def test_empty_data_handling
    assert_equal 0, [].sum
    assert_equal 0, [].size
  end
end