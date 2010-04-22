require 'hpricot'
require 'cgi'

module Hquery
  class Handler
    include Hquery::Common
    def initialize(view)
      @timestart = Time.now
      @view = view
    end
    def self.call(view)
      "#{name}.new(self).render(template, local_assigns)"
    end
    def render(template, local_assigns = {})
      prep_assigns(local_assigns)
      @doc = Hpricot(IO.read(html_template_filename(template.filename)))
      eval(template.source)
      value = @doc.to_s
    ensure
      logger.debug "hquery::render took #{Time.now - @timestart}s for #{template.filename} "
      value
    end
    def compilable?
       ENV['HQUERY_COMPILE'] || RAILS_ENV == 'production'
    end
    def compile_template(template)
      compiled_filename = template.filename.gsub(/hquery$/i, 'html.erb')
      @doc = Hpricot(IO.read(html_template_filename(template.filename)))
      Compiler.new(@doc).compile(template.source, compiled_filename)
    end
    protected
      def debug_schema
        (@doc/"head").append(<<-HTML
          <link href="/stylesheets/hquery.css" rel="stylesheet" type="text/css" />
          <script src='/javascripts/hquery-jquery.js'></script>
          <script src='/javascripts/hquery.js'></script>
          HTML
        )
      end
      def select(*args, &block)
        @doc.root.select(*args, &block)
      end
      def remove(selector)
        (@doc/selector).remove
      end
      def logger
        RAILS_DEFAULT_LOGGER
      end
      def prep_assigns(local_assigns)
        @view.assigns.each do |key, value|
          instance_variable_set "@#{key}", value
        end
        # inject local assigns into reader methods
        local_assigns.each do |key, value|
          class << self; self; end.send(:define_method, key) { val }
        end
      end
      def url_for(*args)
        CGI.unescapeHTML(@view.send(:url_for, *args))
      end
      def method_missing(*args)
        # I'm not sure how to properly include the helpers and make it work like ".html.erb"
        if @view
          @view.send(*args)
        else
          super
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
