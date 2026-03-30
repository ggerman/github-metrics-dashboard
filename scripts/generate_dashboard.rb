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
    '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
    '/usr/share/fonts/truetype/ubuntu/Ubuntu-Regular.ttf'
  ]
  fonts.find { |f| File.exist?(f) }
end

FONT_PATH = find_font
puts "🔤 Font: #{FONT_PATH || 'none (text will not render)'}"
puts "🚀 Generating Complete GitHub Metrics Dashboard"
puts "=" * 60

data_sets = {}

repos.each do |repo|
  repo_name = repo['name']
  puts "\n📊 Processing: #{repo_name}"
  
  views_file = "#{DATA_DIR}/#{repo_name}_views.csv"
  clones_file = "#{DATA_DIR}/#{repo_name}_clones.csv"
  referrers_file = "#{DATA_DIR}/#{repo_name}_referrers.csv"
  
  # ============================================================
  # 1. Views Data
  # ============================================================
  if File.exist?(views_file) && File.size(views_file) > 0
    views_data = CSV.parse(File.read(views_file), headers: true)
    dates = views_data.map { |r| Date.parse(r['date']).strftime('%m/%d') }.last(30)
    view_counts = views_data.map { |r| r['count'].to_i }.last(30)
    unique_counts = views_data.map { |r| r['uniques'].to_i }.last(30)
    
    total_views = view_counts.sum
    avg_views = view_counts.empty? ? 0 : (total_views / view_counts.size).round
    total_uniques = unique_counts.sum
    avg_uniques = unique_counts.empty? ? 0 : (total_uniques / unique_counts.size).round
    
    # Week-over-week growth
    if view_counts.size >= 14
      current_week = view_counts.last(7).sum
      previous_week = view_counts[-14..-8].sum
      views_wow = previous_week.zero? ? 0 : ((current_week - previous_week) * 100 / previous_week).round(1)
    else
      views_wow = 0
    end
    
    # Generate views chart
    if view_counts.any? && FONT_PATH
      chart = ProfessionalChart.new(
        width: 900,
        height: 400,
        title: "#{repo['display_name']} - Daily Views Trend",
        font_path: FONT_PATH
      )
      chart.render_line_chart(view_counts, dates, "#{OUTPUT_DIR}/#{repo_name}_views_trend.png")
      puts "  ✅ Views chart generated"
    end
  else
    view_counts = []
    dates = []
    total_views = 0
    avg_views = 0
    total_uniques = 0
    avg_uniques = 0
    views_wow = 0
    puts "  ⚠️ No views data found"
  end
  
  # ============================================================
  # 2. Clones Data
  # ============================================================
  if File.exist?(clones_file) && File.size(clones_file) > 0
    clones_data = CSV.parse(File.read(clones_file), headers: true)
    clone_counts = clones_data.map { |r| r['count'].to_i }.last(30)
    clone_uniques = clones_data.map { |r| r['uniques'].to_i }.last(30)
    
    total_clones = clone_counts.sum
    avg_clones = clone_counts.empty? ? 0 : (total_clones / clone_counts.size).round
    total_clone_uniques = clone_uniques.sum
    
    # Week-over-week growth for clones
    if clone_counts.size >= 14
      current_week_clones = clone_counts.last(7).sum
      previous_week_clones = clone_counts[-14..-8].sum
      clones_wow = previous_week_clones.zero? ? 0 : ((current_week_clones - previous_week_clones) * 100 / previous_week_clones).round(1)
    else
      clones_wow = 0
    end
    
    # Generate clones chart
    if clone_counts.any? && FONT_PATH
      chart = ProfessionalChart.new(
        width: 900,
        height: 400,
        title: "#{repo['display_name']} - Daily Clones Trend",
        font_path: FONT_PATH
      )
      chart.render_line_chart(clone_counts, dates, "#{OUTPUT_DIR}/#{repo_name}_clones_trend.png")
      puts "  ✅ Clones chart generated"
    end
  else
    clone_counts = []
    total_clones = 0
    avg_clones = 0
    total_clone_uniques = 0
    clones_wow = 0
    puts "  ⚠️ No clones data found"
  end
  
  # ============================================================
  # 3. Referrers Data
  # ============================================================
  referrers = []
  if File.exist?(referrers_file) && File.size(referrers_file) > 0
    referrers_data = CSV.parse(File.read(referrers_file), headers: true)
    
    # Aggregate referrers by source (sum counts for each referrer)
    referrer_totals = {}
    referrers_data.each do |row|
      source = row['referrer']
      count = row['count'].to_i
      referrer_totals[source] = (referrer_totals[source] || 0) + count
    end
    
    referrers = referrer_totals.sort_by { |_, count| -count }.first(10).map do |source, count|
      { source: source, count: count }
    end
    puts "  ✅ Referrers data processed: #{referrers.size} sources"
  end
  
  # ============================================================
  # Store all data
  # ============================================================
  data_sets[repo_name] = {
    display_name: repo['display_name'],
    description: repo['description'],
    color: repo['color'],
    views: {
      total: total_views,
      avg: avg_views,
      wow: views_wow,
      uniques: total_uniques,
      avg_uniques: avg_uniques,
      trend: view_counts,
      dates: dates
    },
    clones: {
      total: total_clones,
      avg: avg_clones,
      wow: clones_wow,
      uniques: total_clone_uniques,
      trend: clone_counts
    },
    referrers: referrers
  }
  
  puts "  📈 Views: #{total_views} total, #{avg_views}/day, WoW: #{views_wow}%"
  puts "  📊 Clones: #{total_clones} total, #{avg_clones}/day, WoW: #{clones_wow}%"
  puts "  👥 Unique visitors: #{total_uniques}"
end

# ================================================================
# Generate HTML dashboard
# ================================================================

puts "\n🌐 Generating HTML dashboard..."

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
puts "📊 Charts:"
puts "   - *_views_trend.png (views over time)"
puts "   - *_clones_trend.png (clones over time)"