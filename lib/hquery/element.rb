module Hquery
  module Element
    def self.included(base)
      base.class_eval do
        alias_method_chain :html, :selector
      end
    end
  
    def html_with_selector(selector, value = :html_without_selector, noattr = false)
      return self.html_without_selector(selector) if value == :html_without_selector
      case !noattr && selector
      when /^\@(.+)$/
        self.set_attribute $1, value
      when /.*\[\@([^\]]+)\]/
        (self/selector).each {|e| e.set_attribute($1, value) }
      else
        (self/selector).html(value)
      end
    end

    def attr(selector, key, value = :attr_without_selector)
      if value == :attr_without_selector
        self.set_attribute(selector, key)
      else
        (self/selector).collect {|e| e.set_attribute(key, value) }
      end
    end
  
    def select(selector, list = [{}], &block)
      timestart = Time.now
      (self/selector).each_with_index do |ele, index|
        obj = list[index]
        case obj && block.arity
        when 3
          block.call ele, obj, index
        when 2
          block.call ele, obj
        when nil
          ele.parent.children.delete(ele)
        else
          block.call ele
        end
      end
    rescue
      err_string = "#{$!.inspect}\n#{$!.backtrace.join("\n")}"
      RAILS_DEFAULT_LOGGER.error err_string
      (self/selector).html(RAILS_ENV == 'production' ? "" : CGI.escapeHTML(err_string))
      raise $!
    ensure
      RAILS_DEFAULT_LOGGER.debug "hquery::select took #{Time.now - timestart}s for #{selector.inspect}"
    end
  end
end