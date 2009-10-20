require 'rdoc/parser'
require 'maruku'

class RDoc::Parser::Markdown < RDoc::Parser
  parse_files_matching /\.markdown$/

  def initialize(top_level, file_name, content, options, stats)
    super
  end

  def scan
    @top_level.comment = Maruku.new(@content).to_html
    @top_level.parser = self.class
    @top_level
  end
end
