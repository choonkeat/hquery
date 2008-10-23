require 'hpricot'

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
        self.raw_attr $1, value
      when /.*\[\@([^\]]+)\]/
        (self/selector).each {|e| e.raw_attr($1, value) }
      else
        (self/selector).html(value)
      end
    end

    def attr(selector, key, value = :attr_without_selector)
      if value == :attr_without_selector
        self.raw_attr(selector, key)
      else
        (self/selector).collect {|e| e.raw_attr(key, value) }
      end
    end

    def raw_attr(name, val)
      self.altered!
      self.raw_attributes ||= {}
      self.raw_attributes[name.to_s] = val
    end
  
    def select(selector, list = [{}], &block)
      timestart = Time.now
      selected = (self/selector)
      return if selected.length < 1
      [selected.length, list.length].max.times do |index|
        obj = list[index]
        ele = selected[index] || selected.last.after(selected.first.to_s).first
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

Hpricot::Elem.send(:include, Hquery::Element)
