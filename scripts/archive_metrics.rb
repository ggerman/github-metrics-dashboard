#!/usr/bin/env ruby
# frozen_string_literal: true

# ================================================================
# GitHub Metrics Archiver
# ================================================================
# Author: Germán Alberto Giménez Silva <ggerman@gmail.com>
# Description: Fetches traffic data from GitHub API and stores
#              historical records in CSV files for long-term retention.
#              First run saves last 14 days, subsequent runs only
#              save new data.
# ================================================================

require 'octokit'
require 'csv'
require 'date'
require 'yaml'
require 'optparse'
require 'fileutils'

# ================================================================
# Configuration
# ================================================================

options = {}
OptionParser.new do |opts|
  opts.on('--output PATH', 'Output directory for CSV files') { |v| options[:output] = v }
  opts.on('--config PATH', 'Path to config.yml') { |v| options[:config] = v }
  opts.on('--verbose', 'Enable verbose output') { options[:verbose] = true }
end.parse!

OUTPUT_DIR = options[:output] || 'data/raw'
CONFIG_PATH = options[:config] || 'dashboard/config.yml'
VERBOSE = options[:verbose] || false

TOKEN = ENV['GH_TOKEN']
abort '❌ ERROR: GH_TOKEN environment variable not set' unless TOKEN

# Create output directory if it doesn't exist
FileUtils.mkdir_p(OUTPUT_DIR)

# ================================================================
# Helper: Load existing dates from CSV (to avoid duplicates)
# ================================================================

def load_existing_dates(csv_path, date_column = 'date')
  return [] unless File.exist?(csv_path) && File.size(csv_path) > 0
  
  begin
    CSV.read(csv_path, headers: true).map { |row| row[date_column] }.compact
  rescue => e
    puts "    ⚠️ Warning: Could not read existing CSV: #{e.message}"
    []
  end
end

# ================================================================
# Helper: Filter only new data (avoid duplicates)
# ================================================================

def filter_new_data(existing_dates, new_data, date_field = :timestamp)
  return new_data if existing_dates.empty?
  
  new_data.reject do |item|
    date = item[date_field].to_s
    existing_dates.include?(date)
  end
end

# ================================================================
# Helper: Write data to CSV (append mode)
# ================================================================

def append_to_csv(csv_path, headers, rows)
  is_new_file = !File.exist?(csv_path) || File.size(csv_path) == 0
  
  CSV.open(csv_path, 'a') do |csv|
    csv << headers if is_new_file
    rows.each { |row| csv << row }
  end
  
  rows.size
end

# ================================================================
# Helper: Print verbose output
# ================================================================

def log(message, level: :info)
  return unless VERBOSE || level == :error
  
  prefix = case level
           when :error then '❌'
           when :warn  then '⚠️'
           when :success then '✅'
           else '📊'
           end
  puts "  #{prefix} #{message}"
end

# ================================================================
# Main: Fetch and archive metrics for all repositories
# ================================================================

begin
  # Load configuration
  puts "🚀 GitHub Metrics Archiver"
  puts "=" * 60
  puts "📁 Output directory: #{OUTPUT_DIR}"
  puts "📄 Config file: #{CONFIG_PATH}"
  
  unless File.exist?(CONFIG_PATH)
    abort "❌ ERROR: Config file not found: #{CONFIG_PATH}"
  end
  
  config = YAML.load_file(CONFIG_PATH)
  repos = config['repositories']
  
  puts "📊 Repositories to monitor: #{repos.size}"
  puts "-" * 60
  
  # Initialize GitHub client
  client = Octokit::Client.new(access_token: TOKEN)
  client.auto_paginate = false
  
  total_views = 0
  total_clones = 0
  total_referrers = 0
  
  repos.each_with_index do |repo, index|
    repo_full = "#{repo['owner']}/#{repo['name']}"
    repo_name = repo['name']
    
    puts "\n📦 [#{index + 1}/#{repos.size}] #{repo_full}"
    
    # ============================================================
    # 1. Fetch VIEWS data
    # ============================================================
    begin
      views_data = client.views(repo_full)
      
      if views_data && views_data[:views] && views_data[:views].any?
        csv_path = "#{OUTPUT_DIR}/#{repo_name}_views.csv"
        existing_dates = load_existing_dates(csv_path)
        
        # If this is the first run (no existing dates), we want ALL data
        # GitHub API returns last 14 days by default
        if existing_dates.empty?
          new_views = views_data[:views]
          log "First run - saving all #{new_views.size} days of history", level: :info
        else
          new_views = filter_new_data(existing_dates, views_data[:views], :timestamp)
        end
        
        if new_views.any?
          rows = new_views.map { |v| [v[:timestamp], v[:count], v[:uniques]] }
          added = append_to_csv(csv_path, ['date', 'count', 'uniques'], rows)
          log "#{added} new view records added", level: :success
          total_views += added
        else
          log "No new view records", level: :info
        end
        
        # Show summary
        total_records = File.exist?(csv_path) ? `wc -l < #{csv_path}`.strip.to_i - 1 : 0
        log "Total historical records: #{total_records} days", level: :info if VERBOSE
        
      elsif views_data && views_data[:views] && views_data[:views].empty?
        log "No view data available (repo may be too new or no traffic)", level: :warn
      else
        log "Could not fetch view data", level: :warn
      end
      
    rescue Octokit::NotFound
      log "Repository not found or no access", level: :error
    rescue Octokit::TooManyRequests
      log "Rate limit hit, sleeping 60 seconds...", level: :warn
      sleep 60
      retry
    rescue => e
      log "Error fetching views: #{e.message}", level: :error
    end
    
    # ============================================================
    # 2. Fetch CLONES data
    # ============================================================
    begin
      clones_data = client.clones(repo_full)
      
      if clones_data && clones_data[:clones] && clones_data[:clones].any?
        csv_path = "#{OUTPUT_DIR}/#{repo_name}_clones.csv"
        existing_dates = load_existing_dates(csv_path)
        
        if existing_dates.empty?
          new_clones = clones_data[:clones]
          log "First run - saving all #{new_clones.size} days of history", level: :info
        else
          new_clones = filter_new_data(existing_dates, clones_data[:clones], :timestamp)
        end
        
        if new_clones.any?
          rows = new_clones.map { |c| [c[:timestamp], c[:count], c[:uniques]] }
          added = append_to_csv(csv_path, ['date', 'count', 'uniques'], rows)
          log "#{added} new clone records added", level: :success
          total_clones += added
        else
          log "No new clone records", level: :info
        end
      elsif clones_data && clones_data[:clones] && clones_data[:clones].empty?
        log "No clone data available", level: :warn
      end
      
    rescue Octokit::NotFound
      log "Repository not found or no access", level: :error
    rescue Octokit::TooManyRequests
      log "Rate limit hit, sleeping 60 seconds...", level: :warn
      sleep 60
      retry
    rescue => e
      log "Error fetching clones: #{e.message}", level: :error
    end
    
    # ============================================================
    # 3. Fetch REFERRERS data
    # ============================================================
    begin
      referrers_data = client.top_referrers(repo_full)
      
      if referrers_data && referrers_data.any?
        csv_path = "#{OUTPUT_DIR}/#{repo_name}_referrers.csv"
        current_date = Time.now.utc.iso8601
        
        # Check if we already have referrers for today
        existing_today = false
        if File.exist?(csv_path) && File.size(csv_path) > 0
          existing = CSV.read(csv_path, headers: true)
          existing_today = existing.any? { |row| row['date'].start_with?(Date.today.to_s) }
        end
        
        unless existing_today
          rows = referrers_data.map { |r| [current_date, r[:referrer], r[:count], r[:uniques]] }
          added = append_to_csv(csv_path, ['date', 'referrer', 'count', 'uniques'], rows)
          log "#{added} referrer records saved", level: :success
          total_referrers += added
        else
          log "Referrers already saved for today", level: :info
        end
      else
        log "No referrer data available", level: :warn
      end
      
    rescue Octokit::NotFound
      log "Repository not found or no access", level: :error
    rescue => e
      log "Error fetching referrers: #{e.message}", level: :error
    end
  end
  
  # ================================================================
  # Summary
  # ================================================================
  puts "\n" + "=" * 60
  puts "📊 ARCHIVE SUMMARY"
  puts "=" * 60
  puts "  ✅ Total new view records:     #{total_views}"
  puts "  ✅ Total new clone records:    #{total_clones}"
  puts "  ✅ Total new referrer records: #{total_referrers}"
  puts "  📁 Data stored in: #{OUTPUT_DIR}"
  puts "=" * 60
  puts "✅ Archive completed successfully!"
  
rescue => e
  puts "\n❌ FATAL ERROR: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
