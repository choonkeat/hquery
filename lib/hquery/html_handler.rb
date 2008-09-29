module Hquery
  class HtmlHandler
    def initialize(view)
    end
    def render(template, local_assigns = {})
      RAILS_DEFAULT_LOGGER.debug "Rendering with #{self.class}"
      template.source
    end
    def compilable?
      false
    end
  end
end