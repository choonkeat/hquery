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
    rescue
      err_string = "html(#{selector}) - #{$!.inspect}\n#{$!.backtrace.join("\n")}"
      logger.error err_string
      raise $!
    end

    def attr(selector, key, value = :attr_without_selector)
      if value == :attr_without_selector
        self.set_attribute(selector, key)
      else
        (self/selector).collect {|e| e.set_attribute(key, value) }
      end
    rescue
      err_string = "attr(#{selector}) - #{$!.inspect}\n#{$!.backtrace.join("\n")}"
      logger.error err_string
      raise $!
    end

    def select(selector, list = [{}], &block)
      timestart = Time.now
      (self/selector).each_with_index do |ele, index|
        obj = list && list[index]
        case obj && block && block.arity
        when nil
          ele.parent.children.delete(ele)
        when 3
          block.call ele, obj, index
        when 2
          block.call ele, obj
        else
          block.call ele
        end
      end
    rescue
      err_string = "select(#{selector}) - #{$!.inspect}\n#{$!.backtrace.join("\n")}"
      logger.error err_string
      (self/selector).html(RAILS_ENV == 'production' ? "" : "<pre>#{CGI.escapeHTML(err_string)}</pre>")
    ensure
      logger.debug "hquery::select took #{Time.now - timestart}s for #{selector.inspect}"
    end

    protected
      def logger
        RAILS_DEFAULT_LOGGER
      end
  end
end