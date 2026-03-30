require 'gd'

class TrendChart
  def initialize(width: 800, height: 500, title: '', dates: [], values: [], forecast: [])
    @width, @height, @title, @dates, @values, @forecast = width, height, title, dates, values, forecast
  end
  
  def render(path, font_path = nil)
    @font_path = font_path
    img = GD::Image.new(@width, @height)
    img.filled_rectangle(0,0,@width-1,@height-1,GD::Color.rgb(255,255,255))
    draw_axes(img)
    draw_line(img, @values, GD::Color.rgb(70,130,200))
    draw_line(img, @forecast, GD::Color.rgb(200,100,100)) if @forecast.any?
    draw_title(img)
    img.save(path)
  end
  
  private
  
  def draw_axes(img)
    c = GD::Color.rgb(100,100,100)
    img.line(60,30,60,@height-50,c)
    img.line(60,@height-50,@width-30,@height-50,c)
  end
  
  def draw_line(img, values, color)
    n = values.size
    return if n < 2
    step = (@width-100)/(n-1).to_f
    max_v = [@values.max.to_f, @forecast.max.to_f].max
    max_v = 1 if max_v.zero?
    scale = (@height-100)/max_v
    pts = values.each_with_index.map { |v,i| [60 + i*step, @height-50 - v*scale] }
    pts.each_cons(2) { |a,b| img.line(a[0],a[1],b[0],b[1],color, thickness: 2) }
  end
  
  def draw_title(img)
    return unless @title && @font_path
    img.text(@title, x:30, y:20, font: @font_path, size:14, color: GD::Color.rgb(0,0,0))
  end
end
