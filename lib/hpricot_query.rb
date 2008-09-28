require 'hpricot'
require 'cgi'
# 
# hq(".users_list .user", @users) do |ele, user, index|
#   (ele/".user_username").html(user.username.capitalize)
#   (ele/".user_description").html(user.description)
# end
# 
class HpricotQuery
  def initialize(view)
    logger.info "HpricotQuery:initialize:#{view.class}"
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
  protected
    def debug_schema
      @doc.root.after(<<-HTML
        <link href="/stylesheets/hquery.css" rel="stylesheet" type="text/css" />
        <script src='/javascripts/hquery-jquery.js'></script>
        <script src='/javascripts/hquery.js'></script>
        HTML
      )
    end
    def hq(selector, list)
      selected = (@doc/selector)
      selected.each_with_index do |ele, index|
        if list[index]
          yield ele, list[index], index
        else
          ele.parent.children.delete(ele)
        end
      end
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
end

class HpricotQuery
  class Debug
    def initialize(view)
      logger.info "HpricotQuery:initialize:#{view.class}"
      @view = view
    end
    def render(template, local_assigns = {})
      nil
    end
    def compilable?
      false
    end
    def logger
      RAILS_DEFAULT_LOGGER
    end
  end
end