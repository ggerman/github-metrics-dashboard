#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'date'
require 'csv'
require 'fileutils'
require_relative '../lib/charts/professional_chart'
require_relative '../lib/dashboard/professional_template'

# ================================================================
# Configuration
# ================================================================

OUTPUT_DIR = 'output/dashboard'
DATA_DIR = 'data/raw'

FileUtils.mkdir_p(OUTPUT_DIR)
FileUtils.mkdir_p(DATA_DIR)

# Load configuration
config = YAML.load_file('config.yml')
repos = config['repositories']

# Find font
def find_font
  fonts = [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf'
  ]
  fonts.find { |f| File.exist?(f) }
end

FONT_PATH = find_font
puts "🔤 Font: #{FONT_PATH || 'none (text will not render)'}"

puts "🚀 Generating GitHub Metrics Dashboard"
puts "=" * 60

data_sets = {}

repos.each do |repo|
  repo_name = repo['name']
  puts "\n📊 Processing: #{repo_name}"
  
  views_file = "#{DATA_DIR}/#{repo_name}_views.csv"
  
  if File.exist?(views_file) && File.size(views_file) > 0
    views_data = CSV.parse(File.read(views_file), headers: true)
    dates = views_data.map { |r| Date.parse(r['date']).strftime('%m/%d') }.last(30)
    counts = views_data.map { |r| r['count'].to_i }.last(30)
    
    total_views = counts.sum
    avg_views = counts.empty? ? 0 : (total_views / counts.size).round
    
    # Week-over-week growth
    if counts.size >= 14
      current_week = counts.last(7).sum
      previous_week = counts[-14..-8].sum
      wow_growth = previous_week.zero? ? 0 : ((current_week - previous_week) * 100 / previous_week).round(1)
    else
      wow_growth = 0
    end
    
    # Generate professional chart
    if counts.any? && FONT_PATH
      chart = ProfessionalChart.new(
        width: 900,
        height: 400,
        title: "#{repo['display_name']} - Daily Views Trend"
      )
      chart.font_path = FONT_PATH
      chart.render_line_chart(counts, dates, "#{OUTPUT_DIR}/#{repo_name}_trend.png")
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
# Generate HTML dashboard with professional template
# ================================================================

puts "\n🌐 Generating HTML dashboard..."

require_relative '../lib/dashboard/professional_template'
template = ProfessionalTemplate.new(
  title: config['dashboard']['title'],
  subtitle: config['dashboard']['subtitle'],
  data: data_sets,
  generated_at: Time.now
)

template.render("#{OUTPUT_DIR}/index.html")

puts "\n" + "=" * 60
puts "✅ Dashboard generated successfully!"
puts "📁 Output: #{OUTPUT_DIR}/index.html"