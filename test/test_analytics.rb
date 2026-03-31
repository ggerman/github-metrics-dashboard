# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/analytics/trend_analyzer'

class TestAnalytics < Minitest::Test
  def setup
    @sample_views = [100, 110, 120, 115, 130, 125, 140, 135, 150, 145]
    @sample_dates = (1..10).map { |i| Date.today - i }
    @analyzer = Analytics::TrendAnalyzer.new(@sample_views, @sample_dates)
  end

  def test_total_calculation
    assert_equal 1270, @analyzer.total
  end

  def test_average_calculation
    assert_equal 127, @analyzer.average
  end

  def test_empty_values_total
    analyzer = Analytics::TrendAnalyzer.new([])
    assert_equal 0, analyzer.total
  end

  def test_empty_values_average
    analyzer = Analytics::TrendAnalyzer.new([])
    assert_equal 0, analyzer.average
  end

  def test_wow_growth_with_sufficient_data
    # 14+ days of data: week1 = [100,110,120,130,140,150,160] sum = 910
    #                   week2 = [110,115,125,135,145,155,165] sum = 950
    # growth = (950 - 910) / 910 * 100 = 4.4%
    views = [100, 110, 120, 130, 140, 150, 160,
             110, 115, 125, 135, 145, 155, 165]
    analyzer = Analytics::TrendAnalyzer.new(views)
    assert_in_delta 4.4, analyzer.wow_growth, 0.1
  end

  def test_wow_growth_with_insufficient_data
    analyzer = Analytics::TrendAnalyzer.new([100, 200, 300])
    assert_equal 0, analyzer.wow_growth
  end

  def test_mom_growth_with_sufficient_data
    # 60+ days of data (simplified)
    views = [10] * 30 + [15] * 30
    analyzer = Analytics::TrendAnalyzer.new(views)
    assert_in_delta 50.0, analyzer.mom_growth, 0.1
  end

  def test_growth_rate
    views = [100, 110, 121]  # 10% growth each period
    analyzer = Analytics::TrendAnalyzer.new(views)
    # (121/100)^(1/2) - 1 = 0.1 = 10%
    assert_in_delta 10.0, analyzer.growth_rate, 0.5
  end

  def test_peak_day
    peak = @analyzer.peak_day
    assert_equal 150, peak[:value]
    assert_equal 8, peak[:index]
  end

  def test_forecast_returns_array
    forecast = @analyzer.forecast(5)
    assert_equal 5, forecast.size
    assert forecast.all? { |v| v.is_a?(Numeric) }
  end

  def test_forecast_with_insufficient_data
    analyzer = Analytics::TrendAnalyzer.new([1, 2, 3])
    assert_equal [], analyzer.forecast(5)
  end

  def test_moving_average
    ma = @analyzer.moving_average(3)
    # First MA: (100+110+120)/3 = 110
    # Second: (110+120+115)/3 = 115
    assert_in_delta 110.0, ma[0], 0.1
    assert_in_delta 115.0, ma[1], 0.1
  end
end