require 'hpricot'
require 'cgi'

module Hquery
  class Handler
    def initialize(view)
      @view = view
    end

    def render(template, local_assigns = {})
      timestart = Time.now
      prep_assigns(local_assigns)
      @templatefilename = template.filename
      @templatedir = File.dirname(template.filename)
      html_filename = template.filename.gsub(/hquery$/i, 'html')
      @doc = Hpricot(IO.read(html_filename)) if File.exist?(html_filename)
      eval(template.source)
      value = current_html
    ensure
      logger.debug "hquery::render took #{Time.now - timestart}s for #{template.filename} "
      value
    end

    def compilable?
      not :yet
    end

    def compile_template(*args)
      logger.debug args.inspect
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

      def current_html
        @doc && (@output_only ? (@doc/@output_only) : @doc).to_s
      end

      def html(selector, content)
        (@doc/selector).inner_html = content
      end

      def select(*args, &block)
        @doc.root.select(*args, &block)
      end

      # replaces parts of current DOM with content from another file
      # optionally specify to use only part of this other file
      def snippet_for(selector, options = {}, *args, &block)
        if not options.kind_of?(Hash)
          args.unshift(options)
          options = {}
        end
        filename = (options.delete(:file) || "#{selector.gsub('#', '').gsub(/[^\w\.]/, '-')}.html")
        filename = File.join('..', filename) if filename =~ /^[^\w\.]/
        selector_there = options.delete(:select)
        if not options.keys.empty?
          raise "hquery::use_snippet - unknown keys: #{options.keys.join(', ')}"
        end
        selected = (@doc/selector)
        if not selected.inner_html.blank?
          logger.info "hquery::use_snippet '#{selector}' is not empty in #{@templatefilename}"
        end
        content = IO.read(File.join(@templatedir, filename))
        if selector_there
          content = (Hpricot(content)/selector_there).to_s
        end
        selected.inner_html = content
        select(selector, *args, &block) if block_given?
      end

      def layout_with(filename, selector = "#content")
        filename = File.join('..', params[:controller], "#{filename}.html")
        content = IO.read(File.join(@templatedir, filename))
        newdoc = Hpricot(content)
        (newdoc/selector).inner_html = current_html
        @doc = newdoc
      end

      # affects the final statement of "render", making @doc only return a subset of this document
      def output_only(selector)
        @output_only = selector
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

      # Rails' url_for() escapes the string, this cause double-escaping for us
      # since setting attributes escapes the value as well
      def url_for(*args)
        CGI.unescapeHTML(@view.send(:url_for, *args))
      end

      # Not sure if there's a "proper" way to do this
      def method_missing(*args)
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