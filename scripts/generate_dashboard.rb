#!/usr/bin/env ruby
require 'yaml'
require 'date'
require 'csv'
require 'fileutils'

config = YAML.load_file('config.yml')
OUTPUT_DIR = 'output/dashboard'
FileUtils.mkdir_p(OUTPUT_DIR)

require_relative '../lib/analytics/trend_analyzer'
require_relative '../lib/charts/bar_chart'
require_relative '../lib/charts/trend_chart'
require_relative '../lib/dashboard/html_generator'

def find_font
  ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
   '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf'].find { |f| File.exist?(f) }
end

FONT_PATH = find_font
puts "Font: #{FONT_PATH || 'none'}"

data_sets = {}

config['repositories'].each do |repo|
  repo_name = repo['name']
  views_file = "data/raw/#{repo_name}_views.csv"
  next unless File.exist?(views_file)
  
  views_data = CSV.parse(File.read(views_file), headers: true)
  dates = views_data.map { |r| Date.parse(r['date']) }.last(30)
  counts = views_data.map { |r| r['count'].to_i }.last(30)
  
  analyzer = Analytics::TrendAnalyzer.new(counts, dates)
  
  if FONT_PATH && counts.any?
    chart = TrendChart.new(
      width: 800, height: 400,
      title: "#{repo['display_name']} - Views",
      dates: dates, values: counts,
      forecast: analyzer.forecast(30)
    )
    chart.render("#{OUTPUT_DIR}/#{repo_name}_trend.png", FONT_PATH)
  end
  
  data_sets[repo_name] = {
    display_name: repo['display_name'],
    description: repo['description'],
    color: repo['color'],
    views: { total: analyzer.total, average: analyzer.average, wow_growth: analyzer.wow_growth }
  }
end

dashboard = HTMLGenerator.new(
  title: config['dashboard']['title'],
  subtitle: config['dashboard']['subtitle'],
  data: data_sets,
  generated_at: Time.now
)
dashboard.render("#{OUTPUT_DIR}/index.html")

puts "Dashboard generated!"
