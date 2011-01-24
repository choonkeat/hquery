require 'hpricot'

module Hquery
  class Handler < ActionView::Template::Handler
    def initialize(doc)
      @doc = doc
    end
    def select(*args, &block)
      @doc.root.select(*args, &block)
    end
    def remove(selector)
      (@doc/selector).remove
    end
    def logger
      ::Rails.logger
    end
    class << self
      include Hquery::Common
      def call(template)
        "begin;doc = Hpricot(IO.read(#{html_template_filename(template.inspect).inspect}));hquery = Hquery::Handler.new(doc);#{template.source}\ndoc.to_s;end"
      end
    end
  end
  module VERSION
    MAJOR = 0
    MINOR = 1
    TINY  = 0
    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end

ActionView::Template.register_template_handler :hquery, Hquery::Handler
