require 'hpricot'
require 'cgi'
# 
# hq(".users_list .user", @users) do |ele, user, index|
#   (ele/".user_username").html(user.username.capitalize)
#   (ele/".user_description").html(user.description)
# end
# 
module Hquery
  class Handler
    def initialize(view)
      @timestart = Time.now
      @view = view
    end
    def render(template, local_assigns = {})
      prep_assigns(local_assigns)
      template_filename = template.filename.gsub(/hquery$/i, 'html')
      @doc = Hpricot(IO.read(template_filename))
      eval(template.source)
      @doc.to_s
    end
    def compilable?
      false
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
      def select(*args, &block)
        @doc.root.select(*args, &block)
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