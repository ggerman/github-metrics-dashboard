# frozen_string_literal: true

require 'erb'

class ProfessionalTemplate
  attr_reader :title, :subtitle, :data, :generated_at

  def initialize(title:, subtitle:, data:, generated_at:)
    @title = title
    @subtitle = subtitle
    @data = data
    @generated_at = generated_at
  end

  def render(output_path)
    template_path = File.join(__dir__, 'professional_template.html.erb')
    template = File.read(template_path)
    erb = ERB.new(template)
    html = erb.result(binding)
    File.write(output_path, html)
  end

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end