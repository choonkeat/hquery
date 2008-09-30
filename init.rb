ActionView::Template.register_template_handler :hquery, Hquery::Handler
ActionView::Template.register_template_handler :html, Hquery::HtmlHandler
Hpricot::Elem.class_eval do
  def html_with_selector(selector, value = :html_without_selector, noattr = false)
    if value == :html_without_selector
      self.html_without_selector(selector)
    elsif !noattr && selector =~ /.*\[\@([^\]]+)\]/
      (self/selector).each {|e| e.set_attribute($1, value) }
    else
      (self/selector).html(value)
    end
  end
  alias_method_chain :html, :selector
  def attr(selector, key, value = :attr_without_selector)
    if value == :attr_without_selector
      self.set_attribute(selector, key)
    else
      (self/selector).collect {|e| e.set_attribute(key, value) }
    end
  end
  
  def select(selector, list = [{}], &block)
    selected = (self/selector)
    selected.each_with_index do |ele, index|
      case list[index] && block.arity
      when 3
        block.call ele, list[index], index
      when 2
        block.call ele, list[index]
      when nil
        ele.parent.children.delete(ele)
      else
        block.call ele
      end
    end
  end
end
