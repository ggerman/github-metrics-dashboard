# frozen_string_literal: true

require 'gd'

class ProfessionalChart
  def initialize(width: 900, height: 400, title: '', bg_color: '#ffffff', font_path: nil)
    @width = width
    @height = height
    @title = title
    @bg_color = hex_to_rgb(bg_color)
    @font_path = font_path
  end

  def render_line_chart(values, labels, output_path)
    return if values.empty? || values.all?(&:zero?)
    
    img = GD::Image.new(@width, @height)
    
    # Background
    img.filled_rectangle(0, 0, @width - 1, @height - 1, GD::Color.rgb(*@bg_color))
    
    # Margins
    left_margin = 70
    right_margin = 40
    top_margin = 60
    bottom_margin = 60
    
    chart_width = @width - left_margin - right_margin
    chart_height = @height - top_margin - bottom_margin
    
    # Colors
    grid_color = GD::Color.rgb(235, 235, 240)
    axis_color = GD::Color.rgb(160, 160, 170)
    line_color = GD::Color.rgb(79, 129, 189)
    area_color = GD::Color.rgba(79, 129, 189, 60)
    point_color = GD::Color.rgb(255, 100, 80)
    text_color = GD::Color.rgb(80, 80, 90)
    title_color = GD::Color.rgb(40, 40, 45)
    
    # Horizontal grid
    max_value = values.max.to_f
    max_value = 1 if max_value.zero?
    
    5.times do |i|
      y = top_margin + (chart_height * i / 4.0)
      val = (max_value * (4 - i) / 4.0).to_i
      
      img.line(left_margin, y.to_i, @width - right_margin, y.to_i, grid_color)
      
      if @font_path
        w, h = img.text_bbox(val.to_s, font: @font_path, size: 10)
        img.text(val.to_s, x: left_margin - 15, y: y.to_i + h / 2, 
                 font: @font_path, size: 10, color: text_color)
      end
    end
    
    # X-axis labels
    n = values.size
    step_x = chart_width.to_f / (n - 1)
    
    labels.each_with_index do |label, i|
      x = left_margin + i * step_x
      img.line(x.to_i, top_margin, x.to_i, @height - bottom_margin, grid_color) if i % 5 == 0
      
      if @font_path && (i % 3 == 0 || i == n - 1)
        w, h = img.text_bbox(label, font: @font_path, size: 9)
        img.text(label, x: x.to_i - w / 2, y: @height - bottom_margin + 15,
                 font: @font_path, size: 9, color: text_color)
      end
    end
    
    # Axes
    img.line(left_margin, top_margin, left_margin, @height - bottom_margin, axis_color)
    img.line(left_margin, @height - bottom_margin, @width - right_margin, @height - bottom_margin, axis_color)
    
    # Scale
    scale_y = chart_height.to_f / max_value
    
    points = values.each_with_index.map do |val, i|
      x = left_margin + i * step_x
      y = top_margin + chart_height - (val * scale_y)
      [x.to_i, y.to_i]
    end
    
    # Area fill
    area_points = [[left_margin, @height - bottom_margin]] + points + [[@width - right_margin, @height - bottom_margin]]
    img.filled_polygon(area_points, area_color) if area_points.size >= 3
    
    # Line
    points.each_cons(2) do |p1, p2|
      img.line(p1[0], p1[1], p2[0], p2[1], line_color, thickness: 3)
    end
    
    # Points
    points.each do |p|
      img.filled_ellipse(p[0], p[1], 7, 7, point_color)
      img.ellipse(p[0], p[1], 9, 9, GD::Color.rgb(255, 255, 255))
    end
    
    # Title
    if @font_path && !@title.empty?
      img.text(@title, x: left_margin, y: top_margin - 25,
               font: @font_path, size: 14, color: title_color)
    end
    
    img.save(output_path)
    true
  end

  private

  def hex_to_rgb(hex)
    hex = hex.gsub('#', '')
    [hex[0..1].to_i(16), hex[2..3].to_i(16), hex[4..5].to_i(16)]
  end
end