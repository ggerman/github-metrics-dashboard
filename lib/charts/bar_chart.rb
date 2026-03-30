require 'gd'

class BarChart
  def initialize(width: 800, height: 500, title: '', x_labels: [])
    @width, @height, @title, @x_labels = width, height, title, x_labels
  end
  
  def render(values, path, font_path = nil)
    @values, @font_path = values, font_path
    img = GD::Image.new(@width, @height)
    img.filled_rectangle(0, 0, @width-1, @height-1, GD::Color.rgb(255,255,255))
    draw_axes(img)
    draw_bars(img)
    draw_labels(img)
    draw_title(img)
    img.save(path)
  end
  
  private
  
  def draw_axes(img)
    c = GD::Color.rgb(100,100,100)
    img.line(60,30,60,@height-50,c)
    img.line(60,@height-50,@width-30,@height-50,c)
  end
  
  def draw_bars(img)
    n = @values.size
    return if n.zero?
    bar_w = (@width-100)/n.to_f
    max_v = @values.max.to_f
    max_v = 1 if max_v.zero?
    scale = (@height-100)/max_v
    bar_c = GD::Color.rgb(70,130,200)
    @values.each_with_index do |val,i|
      h = val * scale
      x1 = 60 + i*bar_w + 5
      y1 = @height-50-h
      x2 = x1 + bar_w - 10
      y2 = @height-51
      img.filled_rectangle(x1,y1,x2,y2,bar_c)
    end
  end
  
  def draw_labels(img); end
  def draw_title(img); end
end
