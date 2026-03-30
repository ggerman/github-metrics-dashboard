# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/charts/professional_chart'

class TestCharts < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @chart = ProfessionalChart.new(
      width: 400,
      height: 300,
      title: 'Test Chart',
      font_path: '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    )
  end

  def teardown
    FileUtils.remove_entry @temp_dir
  end

  def test_chart_creation
    values = [10, 20, 30, 25, 35, 40, 30]
    labels = %w[Day1 Day2 Day3 Day4 Day5 Day6 Day7]
    output_path = File.join(@temp_dir, 'test_chart.png')
    
    result = @chart.render_line_chart(values, labels, output_path)
    
    assert result, 'Chart should render successfully'
    assert File.exist?(output_path), 'Chart file should be created'
    assert File.size(output_path) > 0, 'Chart file should not be empty'
  end

  def test_empty_values
    result = @chart.render_line_chart([], [], 'empty.png')
    assert_nil result, 'Empty values should return nil'
  end

  def test_single_value
    result = @chart.render_line_chart([10], ['Day1'], File.join(@temp_dir, 'single.png'))
    assert_nil result, 'Single value should return nil'
  end

  def test_zero_values
    values = [0, 0, 0, 0, 0]
    labels = %w[D1 D2 D3 D4 D5]
    output_path = File.join(@temp_dir, 'zero_chart.png')
    
    result = @chart.render_line_chart(values, labels, output_path)
    assert result, 'Chart with zeros should still render'
  end
end