# frozen_string_literal: true

module Analytics
  class TrendAnalyzer
    attr_reader :values, :dates

    def initialize(values, dates = nil)
      @values = values.map(&:to_f)
      @dates = dates
    end

    def total
      @values.sum.round
    end

    def average
      @values.empty? ? 0 : (@values.sum / @values.size).round
    end

    def wow_growth
      return 0 if @values.size < 14

      current_week = @values.last(7).sum
      previous_week = @values[-14..-8].sum
      return 0 if previous_week.zero?

      ((current_week - previous_week) / previous_week * 100).round(1)
    end

    def mom_growth
      return 0 if @values.size < 60

      current_month = @values.last(30).sum
      previous_month = @values[-60..-31].sum
      return 0 if previous_month.zero?

      ((current_month - previous_month) / previous_month * 100).round(1)
    end

    def growth_rate
      return 0 if @values.size < 2

      first = @values.first
      last = @values.last
      return 0 if first.zero?

      periods = @values.size - 1
      ((last / first) ** (1.0 / periods) - 1) * 100
    end

    def peak_day
      return nil if @values.empty?

      max_value = @values.max
      index = @values.index(max_value)
      
      result = { value: max_value.round, index: index }
      result[:date] = @dates[index] if @dates
      result
    end

    def forecast(days = 30)
      return [] if @values.size < 7

      x = (0...@values.size).to_a
      y = @values
      n = x.size
      sum_x = x.sum
      sum_y = y.sum
      sum_xy = x.zip(y).sum { |xi, yi| xi * yi }
      sum_xx = x.sum { |xi| xi * xi }

      slope = (n * sum_xy - sum_x * sum_y).to_f / (n * sum_xx - sum_x * sum_x)
      intercept = (sum_y - slope * sum_x) / n

      last_x = @values.size - 1
      (1..days).map { |i| [slope * (last_x + i) + intercept, 0].max.round }
    end

    def moving_average(window = 7)
      return [] if @values.size < window

      @values.each_cons(window).map { |slice| slice.sum / window.to_f }
    end
  end
end