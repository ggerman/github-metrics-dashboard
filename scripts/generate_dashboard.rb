#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'date'
require 'csv'
require 'fileutils'
require 'gd'

# ================================================================
# Configuration
# ================================================================

OUTPUT_DIR = 'output/dashboard'
DATA_DIR = 'data/raw'

FileUtils.mkdir_p(OUTPUT_DIR)
FileUtils.mkdir_p(DATA_DIR)

# Find font for charts
def find_font
  fonts = [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
    '/usr/share/fonts/truetype/ubuntu/Ubuntu-Regular.ttf'
  ]
  fonts.find { |f| File.exist?(f) }
end

FONT_PATH = find_font
puts "🔤 Font: #{FONT_PATH || 'none (text will not render)'}"

# ================================================================
# Helper: Draw a simple line chart
# ================================================================

def draw_line_chart(values, labels, title, output_path, width = 800, height = 400)
  return if values.empty? || values.all?(&:zero?)
  
  img = GD::Image.new(width, height)
  img.filled_rectangle(0, 0, width - 1, height - 1, GD::Color.rgb(255, 255, 255))
  
  # Draw axes
  axis_color = GD::Color.rgb(100, 100, 100)
  img.line(60, 30, 60, height - 50, axis_color)
  img.line(60, height - 50, width - 30, height - 50, axis_color)
  
  # Calculate scales
  n = values.size
  max_val = values.max.to_f
  max_val = 1 if max_val.zero?
  step_x = (width - 100) / (n - 1).to_f
  scale_y = (height - 100) / max_val
  
  # Draw line
  points = []
  values.each_with_index do |val, i|
    x = 60 + i * step_x
    y = height - 50 - (val * scale_y)
    points << [x, y]
  end
  
  line_color = GD::Color.rgb(70, 130, 200)
  points.each_cons(2) do |p1, p2|
    img.line(p1[0], p1[1], p2[0], p2[1], line_color, thickness: 2)
  end
  
  # Draw points
  point_color = GD::Color.rgb(200, 80, 80)
  points.each do |p|
    img.filled_ellipse(p[0], p[1], 5, 5, point_color)
  end
  
  # Draw labels (only every 3rd label to avoid clutter)
  if FONT_PATH
    labels.each_with_index do |label, i|
      next unless i % 3 == 0 || i == n - 1
      x = 60 + i * step_x
      w, h = img.text_bbox(label.to_s, font: FONT_PATH, size: 9)
      img.text(label.to_s, x: x - w / 2, y: height - 35, font: FONT_PATH, size: 9, color: GD::Color.rgb(80, 80, 80))
    end
    
    # Y axis labels
    5.times do |i|
      val = (max_val * i / 4).to_i
      y = height - 50 - (val * scale_y)
      img.text(val.to_s, x: 35, y: y - 5, font: FONT_PATH, size: 9, color: GD::Color.rgb(80, 80, 80))
    end
    
    # Title
    img.text(title, x: 30, y: 20, font: FONT_PATH, size: 14, color: GD::Color.rgb(0, 0, 0))
  end
  
  img.save(output_path)
  puts "  ✅ Chart saved: #{output_path}"
end

# ================================================================
# Helper: Draw a simple bar chart
# ================================================================

def draw_bar_chart(values, labels, title, output_path, width = 800, height = 400)
  return if values.empty? || values.all?(&:zero?)
  
  img = GD::Image.new(width, height)
  img.filled_rectangle(0, 0, width - 1, height - 1, GD::Color.rgb(255, 255, 255))
  
  # Draw axes
  axis_color = GD::Color.rgb(100, 100, 100)
  img.line(60, 30, 60, height - 50, axis_color)
  img.line(60, height - 50, width - 30, height - 50, axis_color)
  
  # Calculate bar dimensions
  n = values.size
  bar_width = (width - 100) / n.to_f
  max_val = values.max.to_f
  max_val = 1 if max_val.zero?
  scale_y = (height - 100) / max_val
  
  bar_color = GD::Color.rgb(70, 130, 200)
  
  values.each_with_index do |val, i|
    bar_height = val * scale_y
    x1 = 60 + i * bar_width + 5
    y1 = height - 50 - bar_height
    x2 = x1 + bar_width - 10
    y2 = height - 51
    img.filled_rectangle(x1, y1, x2, y2, bar_color)
  end
  
  # Draw labels
  if FONT_PATH
    labels.each_with_index do |label, i|
      x = 60 + i * bar_width + (bar_width / 2)
      w, h = img.text_bbox(label.to_s, font: FONT_PATH, size: 9)
      img.text(label.to_s, x: x - w / 2, y: height - 35, font: FONT_PATH, size: 9, color: GD::Color.rgb(80, 80, 80))
    end
    
    5.times do |i|
      val = (max_val * i / 4).to_i
      y = height - 50 - (val * scale_y)
      img.text(val.to_s, x: 35, y: y - 5, font: FONT_PATH, size: 9, color: GD::Color.rgb(80, 80, 80))
    end
    
    img.text(title, x: 30, y: 20, font: FONT_PATH, size: 14, color: GD::Color.rgb(0, 0, 0))
  end
  
  img.save(output_path)
  puts "  ✅ Chart saved: #{output_path}"
end

# ================================================================
# Main: Generate dashboard
# ================================================================

puts "🚀 Generating GitHub Metrics Dashboard"
puts "=" * 60

# Load configuration
config = YAML.load_file('config.yml')
repos = config['repositories']

data_sets = {}

repos.each do |repo|
  repo_name = repo['name']
  puts "\n📊 Processing: #{repo_name}"
  
  views_file = "#{DATA_DIR}/#{repo_name}_views.csv"
  clones_file = "#{DATA_DIR}/#{repo_name}_clones.csv"
  
  if File.exist?(views_file) && File.size(views_file) > 0
    views_data = CSV.parse(File.read(views_file), headers: true)
    dates = views_data.map { |r| Date.parse(r['date']).strftime('%m/%d') }.last(30)
    counts = views_data.map { |r| r['count'].to_i }.last(30)
    
    total_views = counts.sum
    avg_views = counts.empty? ? 0 : (total_views / counts.size).round
    
    # Calculate week-over-week growth
    if counts.size >= 14
      current_week = counts.last(7).sum
      previous_week = counts[-14..-8].sum
      wow_growth = previous_week.zero? ? 0 : ((current_week - previous_week) * 100 / previous_week).round(1)
    else
      wow_growth = 0
    end
    
    # Draw trend chart
    if counts.any? && FONT_PATH
      draw_line_chart(counts, dates, "#{repo['display_name']} - Views Trend", "#{OUTPUT_DIR}/#{repo_name}_trend.png")
    end
    
    data_sets[repo_name] = {
      display_name: repo['display_name'],
      description: repo['description'],
      total_views: total_views,
      avg_views: avg_views,
      wow_growth: wow_growth
    }
    
    puts "  📈 Views: #{total_views} total, #{avg_views} avg/day, WoW: #{wow_growth}%"
  else
    puts "  ⚠️ No views data found for #{repo_name}"
    data_sets[repo_name] = {
      display_name: repo['display_name'],
      description: repo['description'],
      total_views: 0,
      avg_views: 0,
      wow_growth: 0
    }
  end
end

# ================================================================
# Generate HTML dashboard
# ================================================================

puts "\n🌐 Generating HTML dashboard..."

html = <<~HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GitHub Metrics Dashboard</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: #f6f8fa;
      color: #24292f;
      line-height: 1.5;
    }
    .container { max-width: 1200px; margin: 0 auto; padding: 32px 24px; }
    .header { margin-bottom: 32px; }
    .header h1 { font-size: 32px; font-weight: 700; margin-bottom: 8px; }
    .header .subtitle { color: #57606a; font-size: 16px; }
    .header .timestamp { margin-top: 16px; font-size: 13px; color: #6e7781; }
    .badge { background: #e1e4e8; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: 500; }
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; margin-bottom: 40px; }
    .stat-card {
      background: white; border-radius: 16px; padding: 24px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.08); border: 1px solid #e1e4e8;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .stat-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,0.12); }
    .stat-card h3 { font-size: 14px; font-weight: 500; color: #57606a; margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; }
    .stat-value { font-size: 36px; font-weight: 700; color: #24292f; margin-bottom: 8px; }
    .stat-desc { font-size: 13px; color: #57606a; margin-bottom: 16px; }
    .growth { font-size: 13px; font-weight: 600; padding: 2px 8px; border-radius: 20px; display: inline-block; }
    .growth.positive { background: #d4edda; color: #22863a; }
    .growth.negative { background: #ffe0e0; color: #cb2431; }
    .growth.neutral { background: #e1e4e8; color: #586069; }
    .chart-card { background: white; border-radius: 16px; padding: 20px; margin-top: 24px; border: 1px solid #e1e4e8; }
    .chart-card h3 { font-size: 16px; font-weight: 600; margin-bottom: 16px; }
    .chart-card img { width: 100%; height: auto; border-radius: 8px; }
    .footer { margin-top: 48px; padding-top: 24px; border-top: 1px solid #e1e4e8; text-align: center; font-size: 12px; color: #6e7781; }
    .footer a { color: #4a90e2; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📊 GitHub Metrics Dashboard</h1>
      <div class="subtitle">Traffic analytics for open source projects</div>
      <div class="timestamp">Updated: #{Time.now.strftime('%Y-%m-%d %H:%M UTC')}</div>
    </div>

    <div class="stats-grid">
HTML

data_sets.each do |name, repo|
  growth_class = repo[:wow_growth] > 0 ? 'positive' : (repo[:wow_growth] < 0 ? 'negative' : 'neutral')
  growth_sign = repo[:wow_growth] > 0 ? '+' : ''
  
  html += <<~HTML
      <div class="stat-card">
        <h3>#{repo[:display_name]}</h3>
        <div class="stat-value">#{repo[:total_views]}</div>
        <div class="stat-desc">#{repo[:description]}</div>
        <div>📈 Daily avg: #{repo[:avg_views]} views</div>
        <div style="margin-top: 8px;"><span class="growth #{growth_class}">#{growth_sign}#{repo[:wow_growth]}%</span> vs last week</div>
      </div>
  HTML
end

html += <<~HTML
    </div>
HTML

# Add charts if they exist
data_sets.each do |name, repo|
  chart_file = "#{OUTPUT_DIR}/#{name}_trend.png"
  if File.exist?(chart_file)
    html += <<~HTML
      <div class="chart-card">
        <h3>📈 #{repo[:display_name]} - Views Trend (Last 30 Days)</h3>
        <img src="#{name}_trend.png" alt="#{repo[:display_name]} Trend Chart">
      </div>
    HTML
  end
end

html += <<~HTML
    <div class="footer">
      <p>Generated with <strong>ruby-libgd</strong> • <a href="https://github.com/ggerman/ruby-libgd">github.com/ggerman/ruby-libgd</a></p>
      <p>Created by <strong>Germán Alberto Giménez Silva</strong> &lt;ggerman@gmail.com&gt;</p>
    </div>
  </div>
</body>
</html>
HTML

File.write("#{OUTPUT_DIR}/index.html", html)
puts "✅ HTML dashboard saved: #{OUTPUT_DIR}/index.html"
puts "\n" + "=" * 60
puts "✅ Dashboard generated successfully!"
