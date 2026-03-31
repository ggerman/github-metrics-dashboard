def test_single_value
  values = [10]
  labels = ['Day1']
  output_path = File.join(@temp_dir, 'single.png')
  
  result = @chart.render_line_chart(values, labels, output_path)
  assert_nil result, 'Single value should return nil (not enough points for a line)'
end

def test_zero_values
  values = [0, 0, 0, 0, 0]
  labels = %w[D1 D2 D3 D4 D5]
  output_path = File.join(@temp_dir, 'zero_chart.png')
  
  result = @chart.render_line_chart(values, labels, output_path)
  assert_nil result, 'All zeros should return nil (nothing to plot)'
end