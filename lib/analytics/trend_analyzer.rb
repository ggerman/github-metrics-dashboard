module Analytics
  class TrendAnalyzer
    attr_reader :values, :dates
    def initialize(values, dates)
      @values = values.map(&:to_f)
      @dates = dates
    end
    
    def wow_growth
      return 0 if @values.size < 14
      curr = @values.last(7).sum
      prev = @values[-14..-8].sum
      prev.zero? ? 0 : ((curr - prev) / prev * 100).round(1)
    end
    
    def total; @values.sum.round; end
    def average; (@values.sum / @values.size).round; end
    
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
  end
end
