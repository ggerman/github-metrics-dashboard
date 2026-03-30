#!/usr/bin/env ruby
require 'octokit'
require 'csv'
require 'yaml'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on('--output PATH', 'Output directory') { |v| options[:output] = v }
end.parse!

OUTPUT_DIR = options[:output] || 'data/raw'
TOKEN = ENV['GITHUB_TOKEN']
abort 'GITHUB_TOKEN not set' unless TOKEN

client = Octokit::Client.new(access_token: TOKEN)
config = YAML.load_file('config.yml')

config['repositories'].each do |repo|
  repo_full = "#{repo['owner']}/#{repo['name']}"
  puts "Processing: #{repo_full}"
  
  begin
    views = client.views(repo_full)
    if views && views[:views]
      CSV.open("#{OUTPUT_DIR}/#{repo['name']}_views.csv", 'a') do |csv|
        csv << ['date', 'count', 'uniques'] if File.zero?("#{OUTPUT_DIR}/#{repo['name']}_views.csv")
        views[:views].each { |v| csv << [v[:timestamp], v[:count], v[:uniques]] }
      end
    end
    
    clones = client.clones(repo_full)
    if clones && clones[:clones]
      CSV.open("#{OUTPUT_DIR}/#{repo['name']}_clones.csv", 'a') do |csv|
        csv << ['date', 'count', 'uniques'] if File.zero?("#{OUTPUT_DIR}/#{repo['name']}_clones.csv")
        clones[:clones].each { |c| csv << [c[:timestamp], c[:count], c[:uniques]] }
      end
    end
    
    referrers = client.top_referrers(repo_full)
    if referrers
      CSV.open("#{OUTPUT_DIR}/#{repo['name']}_referrers.csv", 'a') do |csv|
        csv << ['date', 'referrer', 'count', 'uniques'] if File.zero?("#{OUTPUT_DIR}/#{repo['name']}_referrers.csv")
        referrers.each { |r| csv << [Time.now.iso8601, r[:referrer], r[:count], r[:uniques]] }
      end
    end
  rescue => e
    puts "Error: #{e.message}"
  end
end
puts "Done!"
