module ApplicationHelper
  
  def make_section header,html_options = {},&block
    the_content = capture(&block)
    the_header = content_tag :h1, header
    the_header = content_tag :header, the_header
    content_tag :section,(the_header+the_content),html_options
  end
end
