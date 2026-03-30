class HTMLGenerator
  def initialize(title:, subtitle:, data:, generated_at:)
    @title, @subtitle, @data, @generated_at = title, subtitle, data, generated_at
  end
  
  def render(output_path)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>#{@title}</title>
      <style>
        body { font-family: sans-serif; background: #f6f8fa; padding: 40px; }
        .card { background: white; border-radius: 12px; padding: 24px; margin-bottom: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        h1 { margin: 0 0 8px 0; }
        .stats { display: flex; gap: 20px; flex-wrap: wrap; }
        .stat { background: #f6f8fa; padding: 16px; border-radius: 8px; min-width: 150px; }
        .stat-value { font-size: 32px; font-weight: bold; }
        img { max-width: 100%; border-radius: 8px; margin-top: 16px; }
        .footer { text-align: center; margin-top: 40px; color: #666; font-size: 12px; }
      </style>
      </head>
      <body>
      <div style="max-width:1200px;margin:0 auto">
      <h1>#{@title}</h1>
      <p>#{@subtitle} | Updated: #{@generated_at.strftime('%Y-%m-%d %H:%M UTC')}</p>
    HTML
    
    @data.each do |name, repo|
      html << <<~HTML
        <div class="card">
          <h2>#{repo[:display_name]}</h2>
          <p>#{repo[:description]}</p>
          <div class="stats">
            <div class="stat"><div class="stat-value">#{repo[:views][:total]}</div><div>Total Views</div></div>
            <div class="stat"><div class="stat-value">#{repo[:views][:average]}</div><div>Daily Avg</div></div>
            <div class="stat"><div class="stat-value">#{repo[:views][:wow_growth]}%</div><div>Week-over-Week</div></div>
          </div>
          <img src="#{name}_trend.png" alt="Trend Chart">
        </div>
      HTML
    end
    
    html << <<~HTML
      <div class="footer">
        Generated with ruby-libgd • <a href="https://github.com/ggerman/ruby-libgd">github.com/ggerman/ruby-libgd</a><br>
        Created by Germán Alberto Giménez Silva &lt;ggerman@gmail.com&gt;
      </div>
      </div></body></html>
    HTML
    
    File.write(output_path, html)
  end
end
